// Wi‑Fi Offline (Plain JSON) – SwiftUI MVP
// Single-file UI plus helpers. Works offline; stores in plain JSON; build unsigned on CI.

import SwiftUI
import NetworkExtension
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
import UIKit

struct WiFiNetwork: Identifiable, Codable, Equatable {
    var id = UUID()
    var ssid: String
    var security: Security = .wpa2
    var password: String
    var note: String?
    var updatedAt = Date()

    enum Security: String, CaseIterable, Codable, Identifiable {
        case open, wep, wpa, wpa2, wpa3
        var id: String { rawValue }
    }
}

@MainActor
final class NetworksStore: ObservableObject {
    @Published private(set) var items: [WiFiNetwork] = []
    private let url: URL
    private let fm = FileManager.default

    init(filename: String = "wifi.json") {
        let appSup = try! fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url = appSup.appendingPathComponent(filename)
        Task { await load() }
    }

    func load() async {
        if !fm.fileExists(atPath: url.path) { items = []; return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            items = decoded.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            print("Load error: \(error)"); items = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            let tmp = url.appendingPathExtension("tmp")
            try data.write(to: tmp, options: .atomic)
            if fm.fileExists(atPath: url.path) { try fm.removeItem(at: url) }
            try fm.moveItem(at: tmp, to: url)
        } catch {
            print("Persist error: \(error)")
        }
    }

    func upsert(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            var m = item; m.updatedAt = .now; items[idx] = m
        } else {
            var m = item; m.updatedAt = .now; items.insert(m, at: 0)
        }
        persist()
    }

    func delete(_ item: WiFiNetwork) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    func exportJSON() throws -> URL {
        let data = try JSONEncoder().encode(items)
        let out = fm.temporaryDirectory.appendingPathComponent("wifi_export_\(Int(Date().timeIntervalSince1970)).json")
        try data.write(to: out, options: .atomic)
        return out
    }

    func `import`(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let incoming = try JSONDecoder().decode([WiFiNetwork].self, from: data)
        var dict = Dictionary(uniqueKeysWithValues: items.map { ($0.ssid + "|" + $0.security.rawValue, $0) })
        for e in incoming {
            let key = e.ssid + "|" + e.security.rawValue
            if var exist = dict[key] {
                if exist.password != e.password || e.updatedAt > exist.updatedAt {
                    exist.password = e.password
                    exist.note = e.note ?? exist.note
                    exist.updatedAt = max(exist.updatedAt, e.updatedAt)
                    dict[key] = exist
                }
            } else {
                dict[key] = e
            }
        }
        items = Array(dict.values).sorted { $0.updatedAt > $1.updatedAt }
        persist()
    }
}

func connectTo(ssid: String, pass: String, security: WiFiNetwork.Security, joinOnce: Bool = false, completion: @escaping (Error?) -> Void) {
    let config: NEHotspotConfiguration
    switch security {
    case .open:
        config = NEHotspotConfiguration(ssid: ssid)
    case .wep:
        config = NEHotspotConfiguration(ssid: ssid, wepPassphrase: pass)
    default:
        config = NEHotspotConfiguration(ssid: ssid, passphrase: pass, isWEP: false)
    }
    config.joinOnce = joinOnce
    NEHotspotConfigurationManager.shared.apply(config) { err in
        DispatchQueue.main.async { completion(err) }
    }
}

func wifiQRString(ssid: String, security: WiFiNetwork.Security, password: String) -> String {
    let T: String = {
        switch security {
        case .open: return "nopass"
        case .wep:  return "WEP"
        default:    return "WPA"
        }
    }()
    return "WIFI:T:\(T);S:\(ssid);P:\(password);;"
}

func makeQR(from string: String, scale: CGFloat = 6) -> UIImage {
    let data = Data(string.utf8)
    let filter = CIFilter.qrCodeGenerator()
    filter.setValue(data, forKey: "inputMessage")
    let transform = CGAffineTransform(scaleX: scale, y: scale)
    let output = filter.outputImage!.transformed(by: transform)
    return UIImage(ciImage: output)
}

struct ContentView: View {
    @StateObject private var store = NetworksStore()
    @State private var showEditor = false
    @State private var editing: WiFiNetwork? = nil
    @State private var exportURL: URL? = nil
    @State private var showImporter = false
    @State private var search = ""
    @State private var alertMsg: String?

    var body: some View {
        NavigationView {
            List {
                ForEach(filtered) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.ssid).font(.headline)
                            Spacer()
                            Button("Kết nối") {
                                connectTo(ssid: item.ssid, pass: item.password, security: item.security) { err in
                                    alertMsg = err?.localizedDescription ?? "Đã áp dụng cấu hình cho \(item.ssid)"
                                }
                            }.buttonStyle(.bordered)
                        }
                        Text("Bảo mật: \(item.security.rawValue.uppercased())")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if let note = item.note, !note.isEmpty {
                            Text(note).font(.footnote)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editing = item; showEditor = true }
                    .swipeActions {
                        Button(role: .destructive) { store.delete(item) } label: {
                            Label("Xóa", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: store.delete)
            }
            .searchable(text: $search)
            .navigationTitle("Wi‑Fi Offline")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showImporter = true } label: { Label("Nhập", systemImage: "square.and.arrow.down") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { if let url = try? store.exportJSON() { exportURL = url } } label: { Label("Xuất", systemImage: "square.and.arrow.up") }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { editing = WiFiNetwork(ssid: "", security: .wpa2, password: "", note: nil); showEditor = true } label: { Label("Thêm", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showEditor) {
                if let editing {
                    EditorView(item: editing) { result, saved in
                        if saved { store.upsert(result) }
                        showEditor = false
                    }
                }
            }
            .sheet(item: $exportURL) { url in
                ShareSheet(items: [url])
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType.json]) { res in
                if case .success(let url) = res { try? store.import(from: url) }
            }
            .alert(item: Binding(
                get: { alertMsg.map { AlertItem(message: $0) } },
                set: { _ in alertMsg = nil })
            ) { item in
                Alert(title: Text(item.message))
            }
        }
    }

    var filtered: [WiFiNetwork] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.items }
        return store.items.filter { $0.ssid.lowercased().contains(q) || ($0.note ?? "").lowercased().contains(q) }
    }
}

struct AlertItem: Identifiable { let id = UUID(); let message: String }

struct EditorView: View {
    @State var item: WiFiNetwork
    var onDone: (WiFiNetwork, Bool) -> Void // (item, saved?)

    var body: some View {
        NavigationView {
            Form {
                TextField("SSID", text: $item.ssid)
                Picker("Bảo mật", selection: $item.security) {
                    ForEach(WiFiNetwork.Security.allCases) { sec in
                        Text(sec.rawValue.uppercased()).tag(sec)
                    }
                }
                if item.security != .open {
                    SecureField("Mật khẩu", text: $item.password)
                }
                TextField("Ghi chú", text: Binding(
                    get: { item.note ?? "" },
                    set: { item.note = $0.isEmpty ? nil : $0 }
                ))
                Section("QR Wi‑Fi") {
                    if item.security == .open || !item.password.isEmpty {
                        let qrStr = wifiQRString(ssid: item.ssid, security: item.security, password: item.password)
                        Image(uiImage: makeQR(from: qrStr)).resizable().interpolation(.none).scaledToFit()
                    } else {
                        Text("Nhập SSID & mật khẩu để tạo QR")
                    }
                }
            }
            .navigationTitle("Mạng Wi‑Fi")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { onDone(item, true) }
                        .disabled(item.ssid.isEmpty || (item.security != .open && item.password.isEmpty))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { onDone(item, false) }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

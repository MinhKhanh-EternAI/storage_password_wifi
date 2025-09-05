import SwiftUI

struct ContentView: View {
    @StateObject private var store = WiFiStore()

    @State private var showingAdd = false
    @State private var showingScanner = false
    @State private var searchText = ""
    @State private var pendingNewSSID: String?

    var filteredItems: [WiFiNetwork] {
        let key = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return store.items }
        return store.items.filter { $0.ssid.lowercased().contains(key) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Đã lưu") {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            WiFiDetailView(item: item, onUpdate: { store.update($0) }, onDelete: {
                                store.delete(item)
                            })
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.ssid)
                                        .font(.headline)
                                    Text(item.security.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(item)
                            } label: {
                                Label("Xoá", systemImage: "trash")
                            }
                        }
                    }
                }

                Section("Mạng hiện tại") {
                    CurrentWiFiRow { ssid in
                        pendingNewSSID = ssid
                        showingAdd = true
                    }
                }
            }
            .navigationTitle("Wi-Fi")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Tìm theo tên mạng")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingScanner = true
                    } label: { Image(systemName: "qrcode.viewfinder") }

                    Button {
                        pendingNewSSID = nil
                        showingAdd = true
                    } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                WiFiFormView(
                    item: WiFiNetwork(
                        ssid: (pendingNewSSID ?? ""),
                        password: nil,
                        security: .wpa2Wpa3,
                        addressPrivacy: .off
                    )
                ) { newItem in
                    store.upsert(newItem)
                }
                .navigationTitle(pendingNewSSID == nil ? "Thêm Wi-Fi" : "Lưu Wi-Fi")
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingScanner) {
            QRScannerView { result in
                switch result {
                case .success(let parsed):
                    let sec: SecurityType = {
                        let t = parsed.type.uppercased()
                        if t == "NOPASS" { return .none }
                        if t == "WEP" { return .wep }
                        if t == "WPA3" { return .wpa3 }
                        return .wpa2Wpa3
                    }()
                    let item = WiFiNetwork(
                        ssid: parsed.ssid,
                        password: parsed.password.isEmpty ? nil : parsed.password,
                        security: sec,
                        addressPrivacy: .off
                    )
                    store.upsert(item)
                    showingScanner = false
                case .failure:
                    showingScanner = false
                }
            }
        }
    }
}

private struct CurrentWiFiRow: View {
    @State private var ssid: String? = nil
    let onAdd: (String) -> Void

    var body: some View {
        HStack {
            Text(ssid ?? "Không xác định")
                .font(.body)
            Spacer()
            Button {
                if let s = ssid { onAdd(s) }
            } label: {
                Label("Thêm mật khẩu", systemImage: "key.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(ssid == nil)
        }
        .task {
            ssid = await CurrentWiFi.currentSSID()
        }
    }
}

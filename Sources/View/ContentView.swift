import SwiftUI

struct ContentView: View {
    @StateObject private var store = WiFiStore()

    @State private var showingAdd = false
    @State private var showingScanner = false
    @State private var searchText = ""

    var filteredItems: [WiFiNetwork] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return store.items
        }
        let key = searchText.lowercased()
        return store.items.filter { $0.ssid.lowercased().contains(key) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Đã lưu") {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            WiFiDetailView(item: item, onUpdate: { updated in
                                store.update(updated)
                            }, onDelete: {
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
                            .contentShape(Rectangle())
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.delete(item)
                            } label: {
                                Label("Xoá", systemImage: "trash")
                            }
                        }
                    }
                }

                Section("Mạng hiện tại") {
                    CurrentWiFiView { ssid in
                        // Nhấn “Thêm mật khẩu” sẽ mở form với sẵn tên mạng
                        showingAdd = true
                        pendingNewSSID = ssid
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Tìm theo tên mạng")
            .navigationTitle("Wi-Fi")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    Button {
                        pendingNewSSID = nil
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            WiFiFormSheet(
                ssid: pendingNewSSID ?? "",
                onSave: { newItem in
                    store.upsert(newItem)
                }
            )
        }
        .sheet(isPresented: $showingScanner) {
            QRScannerView { result in
                switch result {
                case .success(let parsed):
                    // Map chuẩn parser -> model mới
                    let sec: SecurityType = {
                        let t = parsed.type.uppercased()
                        if t == "NOPASS" { return .none }
                        if t == "WEP" { return .wep }
                        if t == "WPA3" { return .wpa3 }
                        // các kiểu còn lại gộp về WPA2/WPA3 theo yêu cầu
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

    // MARK: - Local state
    @State private var pendingNewSSID: String?
}

/// View nhỏ hiển thị mạng hiện tại + nút thêm mật khẩu
private struct CurrentWiFiView: View {
    @State private var ssid: String? = nil
    let onAdd: (String) -> Void

    init(onAdd: @escaping (String) -> Void) {
        self.onAdd = onAdd
    }

    var body: some View {
        HStack {
            Text(ssid ?? "Không xác định")
                .font(.body)
            Spacer()
            Button {
                if let s = ssid { onAdd(s) }
            } label: {
                Label("Thêm mật khẩu", systemImage: "key.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .disabled(ssid == nil)
        }
        .task {
            ssid = await CurrentWiFi.currentSSID()
        }
    }
}

/// Sheet nhập Wi-Fi (form)
private struct WiFiFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var ssid: String
    @State private var password: String = ""
    @State private var security: SecurityType = .wpa2Wpa3
    @State private var addressPrivacy: AddressPrivacy = .off

    let onSave: (WiFiNetwork) -> Void

    init(ssid: String, onSave: @escaping (WiFiNetwork) -> Void) {
        _ssid = State(initialValue: ssid)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin") {
                    TextField("Tên mạng", text: $ssid)
                    SecureField("Mật khẩu", text: $password)
                }

                Section("Bảo mật") {
                    Picker("Bảo mật", selection: $security) {
                        ForEach(SecurityType.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    Picker("Địa chỉ Wi-Fi bảo mật", selection: $addressPrivacy) {
                        ForEach(AddressPrivacy.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }
            }
            .navigationTitle("Thêm Wi-Fi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        let item = WiFiNetwork(
                            ssid: ssid.trimmingCharacters(in: .whitespacesAndNewlines),
                            password: password.isEmpty ? nil : password,
                            security: security,
                            addressPrivacy: addressPrivacy
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

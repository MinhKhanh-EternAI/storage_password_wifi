import SwiftUI
import NetworkExtension

struct ContentView: View {
    @EnvironmentObject private var store: WiFiStore
    @State private var currentSSID: String? = CurrentWiFi.ssid()
    @State private var showingAdd = false
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            List {
                // Mạng hiện tại (gọn, bên trái là tên — bên phải là nút nhập mật khẩu để lưu)
                Section("MẠNG HIỆN TẠI") {
                    HStack {
                        Text(currentSSID ?? "Không xác định").font(.headline)
                        Spacer()
                        Button {
                            guard let ssid = currentSSID else { return }
                            showingAddFor(ssid: ssid)
                        } label: {
                            Label("Thêm MK", systemImage: "plus.circle")
                        }.labelStyle(.iconOnly)
                    }

                    Button {
                        withAnimation { currentSSID = CurrentWiFi.ssid() }
                    } label: {
                        Label("Làm mới", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }

                // Danh sách đã lưu
                Section {
                    if store.items.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.slash").font(.largeTitle)
                            Text("Chưa có Wi-Fi nào").font(.headline)
                            Text("Nhấn Thêm để lưu mạng Wi-Fi mới.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(store.items) { item in
                            NavigationLink(value: item) {
                                HStack(spacing: 12) {
                                    Image(systemName: "wifi")
                                    VStack(alignment: .leading) {
                                        Text(item.ssid).font(.headline)
                                        Text(item.security.rawValue).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .navigationTitle("Wi-fi")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button("Quét mã QR", systemImage: "qrcode.viewfinder") {
                            showingScanner = true
                        }
                        Button("Thêm thủ công", systemImage: "plus") {
                            showingAdd = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .navigationDestination(for: WiFiNetwork.self) { item in
                WiFiDetailView(item: item)
            }
            .sheet(isPresented: $showingAdd) {
                WiFiFormView(item: .init(ssid: "", password: "", security: .wpa2wpa3, privateAddressing: .off)) { newItem in
                    store.add(newItem)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingScanner) {
                QRScannerSheet()
            }
        }
    }

    private func showingAddFor(ssid: String) {
        showingAdd = true
        // Khi form mở, người dùng điền mk & lưu
    }
}

struct QRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WiFiStore

    var body: some View {
        NavigationStack {
            ZStack {
                QRScannerView { str in
                    if let r = WiFiQRParser.parse(str) {
                        let sec: WiFiSecurity = (r.type.uppercased() == "NOPASS") ? .none : .wpa2wpa3
                        let item = WiFiNetwork(ssid: r.ssid, password: r.password, security: sec, privateAddressing: .off)
                        store.add(item)
                        dismiss()
                    }
                }
                VStack {
                    Text("Quét mã QR Wi-Fi")
                        .font(.headline)
                        .padding(.top, 20)
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Huỷ") { dismiss() } }
            }
        }
    }
}

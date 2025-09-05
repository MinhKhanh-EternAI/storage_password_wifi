import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @State private var showingAdd = false
    @State private var showingImport = false
    @State private var currentSSID: String? = nil
    @State private var isRefreshing = false
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    currentNetworkCard

                    if store.networks.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.networks) { wifi in
                            NavigationLink {
                                WiFiDetailView(network: wifi)
                                    .environmentObject(store)
                            } label: {
                                WiFiRow(network: wifi)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) { store.delete(wifi) } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Wi-fi")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button { showingScanner = true } label: {
                            Label("Quét QR", systemImage: "qrcode.viewfinder")
                        }
                        Button { showingImport = true } label: {
                            Label("Nhập từ tệp", systemImage: "tray.and.arrow.down")
                        }
                        Button { exportAll() } label: {
                            Label("Xuất tất cả", systemImage: "tray.and.arrow.up")
                        }
                    } label: { Image(systemName: "ellipsis.circle") }

                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Thêm")
                }
            }
            .sheet(isPresented: $showingAdd) {
                WiFiFormView(mode: .add(.init()))
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingScanner) {
                QRScannerView { str in
                    if let wifi = WiFiQRParser.parse(str) {
                        store.add(wifi)
                    }
                }
            }
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json]) {
                if case let .success(url) = $0 { store.importFromJSON(url: url) }
            }
            .task { await refreshSSID() }
        }
    }

    // MARK: - Sections

    private var currentNetworkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MẠNG HIỆN TẠI")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                HStack {
                    Text(currentSSID ?? "Không xác định")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        if let ssid = currentSSID {
                            if let saved = store.networks.first(where: { $0.ssid == ssid }) {
                                // mở chi tiết
                                UIApplication.shared.firstKeyWindow?
                                  .rootViewController?
                                  .present(UIHostingController(rootView:
                                    WiFiDetailView(network: saved).environmentObject(store)), animated: true)
                            } else {
                                let draft = WiFiNetwork(ssid: ssid, password: "", security: .wpa2Wpa3, privateAddress: .off)
                                UIApplication.shared.firstKeyWindow?
                                  .rootViewController?
                                  .present(UIHostingController(rootView:
                                    WiFiFormView(mode: .add(draft)).environmentObject(store)), animated: true)
                            }
                        }
                    } label: { Image(systemName: "key.fill") }
                    .buttonStyle(.bordered)

                    Button { Task { await refreshSSID() } } label: {
                        Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                    }
                    .accessibilityLabel("Làm mới")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider().padding(.leading, 16)

                Button {
                    Task { await CurrentWiFi.connectIfSaved(store: store, ssid: currentSSID) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi")
                        Text("Kết nối/đổi mạng")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
                .padding(12)
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash").font(.system(size: 60))
            Text("Chưa có Wi-Fi nào").font(.title3.weight(.semibold))
            Text("Nhấn **Thêm** để lưu mạng Wi-Fi mới.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers
    private func exportAll() {
        guard let url = store.exportToTemp() else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
    }

    private func refreshSSID() async {
        isRefreshing = true
        defer { isRefreshing = false }
        currentSSID = await CurrentWiFi.currentSSID()
    }
}

private struct WiFiRow: View {
    let network: WiFiNetwork
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi").imageScale(.large).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(network.ssid).font(.headline)
                Text(network.security.display).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            if !network.password.isEmpty { Image(systemName: "key.fill").foregroundStyle(.secondary) }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first { $0.isKeyWindow }
    }
}

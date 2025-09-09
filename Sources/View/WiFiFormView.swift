import SwiftUI
import SystemConfiguration.CaptiveNetwork

struct WiFiFormView: View {
    enum Mode { case create, edit }
    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WiFiStore

    @State var item: WiFiNetwork
    @State private var showNameAlert = false
    @State private var pwDraft: String = ""

    // Bắt SSID/BSSID hiện tại (ẩn) chỉ để lưu nếu trùng tên — KHÔNG tự điền tên
    private let currentWiFi = CurrentWiFi()
    @State private var capturedSSIDFromCurrent: String = ""
    @State private var capturedBSSID: String? = nil

    init(mode: Mode, item: WiFiNetwork) {
        self.mode = mode
        self._item = State(initialValue: item)
    }

    var body: some View {
        Form {
            Section {
                let labelWidth: CGFloat = 92

                // TÊN — luôn để người dùng nhập (placeholder “Tên mạng”)
                HStack(spacing: 12) {
                    Text("Tên")
                        .foregroundColor(.primary)
                        .frame(width: labelWidth, alignment: .leading)

                    TextField("", text: $item.ssid, prompt: Text("Tên mạng"))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                }
                .padding(.vertical, 2)

                // MẬT KHẨU
                HStack(spacing: 12) {
                    Text("Mật khẩu")
                        .foregroundColor(.primary)
                        .frame(width: labelWidth, alignment: .leading)

                    SecureField("", text: $pwDraft, prompt: Text("Mật khẩu"))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.asciiCapable)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                        .onChange(of: pwDraft) { newVal in
                            let cleaned = newVal.filter { !$0.isWhitespace }
                            if cleaned != newVal { pwDraft = cleaned }
                            item.password = cleaned.isEmpty ? nil : cleaned
                        }
                }
                .padding(.vertical, 2)

            } header: {
                Text("THÔNG TIN")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            // BẢO MẬT
            Section {
                NavigationLink {
                    SecurityPickerView(
                        security: $item.security,
                        privacy: $item.macPrivacy
                    )
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("BẢO MẬT")
                    .textCase(.uppercase)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            pwDraft = item.password ?? ""

            // Chỉ bắt SSID + BSSID hiện tại để lưu ẩn (KHÔNG gán vào item.ssid)
            currentWiFi.fetchSSID { ssid in
                capturedSSIDFromCurrent = ssid ?? ""
                capturedBSSID = readCurrentBSSID()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Hủy") { dismiss() }
            }
            ToolbarItem(placement: .principal) {
                Text(mode == .create ? "Thêm Wi-Fi" : "Sửa Wi-Fi")
                    .font(.system(size: 18, weight: .bold))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Lưu") { save() }
                    .fontWeight(.bold)
                    .disabled(!isSSIDValid)
            }
        }
        .alert("Vui lòng nhập tên Wi-Fi", isPresented: $showNameAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: - Helpers

    private var isSSIDValid: Bool {
        !item.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard isSSIDValid else {
            showNameAlert = true
            return
        }
        if (item.password ?? "").isEmpty { item.security = .none }

        // Nếu đang thêm mới và tên trùng mạng hiện tại → gắn BSSID ẩn
        if mode == .create,
           !capturedSSIDFromCurrent.isEmpty,
           item.ssid == capturedSSIDFromCurrent,
           let b = capturedBSSID, !b.isEmpty {
            item.bssid = b
        }

        store.upsert(item)
        store.sortInPlace()

        if mode == .create {
            NotificationCenter.default.post(name: Notification.Name("wifiDidAdd"), object: nil, userInfo: ["ssid": item.ssid])
        }
        dismiss()
    }

    private func readCurrentBSSID() -> String? {
        guard let ifaces = CNCopySupportedInterfaces() as? [CFString] else { return nil }
        for i in ifaces {
            if let info = CNCopyCurrentNetworkInfo(i) as? [String: AnyObject],
               let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String {
                return bssid
            }
        }
        return nil
    }
}

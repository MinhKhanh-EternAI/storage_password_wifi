import SwiftUI

struct WiFiFormView: View {
    enum Mode { case create, edit }
    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WiFiStore

    @State var item: WiFiNetwork
    @State private var showNameAlert = false
    // soạn thảo mật khẩu (chặn space khi gõ)
    @State private var pwDraft: String = ""

    // NEW: BSSID ẩn bắt từ "mạng hiện tại"
    private let currentWiFi = CurrentWiFi()
    @State private var capturedSSIDFromCurrent: String = ""
    @State private var capturedBSSID: String? = nil

    var body: some View {
        Form {
            // THÔNG TIN
            Section {
                let labelWidth: CGFloat = 92

                // TÊN
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

                // MẬT KHẨU — SecureField + chặn space khi gõ
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

            // Chỉ auto-bắt BSSID khi thêm mới (mode.create). UI không hiển thị trường này.
            if mode == .create {
                currentWiFi.fetchCurrent { ssid, bssid in
                    capturedSSIDFromCurrent = ssid ?? ""
                    capturedBSSID = bssid
                    // Nếu form chưa có SSID, tự điền SSID hiện tại để user đỡ gõ
                    if item.ssid.isEmpty, let s = ssid { item.ssid = s }
                }
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
        // Khi Lưu: nếu mật khẩu rỗng -> set bảo mật = Không có
        if (item.password ?? "").isEmpty { item.security = .none }

        // Nếu đang thêm mới và SSID khớp “mạng hiện tại” -> lưu BSSID ẩn
        if mode == .create,
           !capturedSSIDFromCurrent.isEmpty,
           item.ssid == capturedSSIDFromCurrent {
            item.bssid = capturedBSSID
        }

        // DÙ create hay edit, luôn dùng upsert để xử lý trùng BSSID
        store.upsert(item)
        store.sortInPlace()

        if mode == .create {
            NotificationCenter.default.post(name: Notification.Name("wifiDidAdd"), object: nil)
        }
        dismiss()
    }
}

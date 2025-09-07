import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false
    @State private var copied = false

    // soạn thảo mật khẩu (chặn space khi gõ)
    @State private var pwDraft: String = ""

    var body: some View {
        List {
            infoSection
            securitySection
            qrSection
        }
        .onAppear { pwDraft = item.password ?? "" }          // init draft
        .navigationTitle(item.ssid.isEmpty ? "Wi-Fi" : item.ssid)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // nút "Trở về"
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Trở về")
                    }
                }
            }
            topMenu
        }
        .alert("Bạn có chắc chắn muốn xóa?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                store.delete(item.id); dismiss()
            }
        }
        .toast(isPresented: $copied, text: "Đã sao chép mật khẩu")
        // nút Lưu cố định dưới – nền xanh chữ trắng
        .safeAreaInset(edge: .bottom) {
            Button {
                // nếu không có mật khẩu -> tự set Không có
                if (item.password ?? "").isEmpty { item.security = .none }
                store.upsert(item)
            } label: {
                Text("Lưu thông tin")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Sections

    private var infoSection: some View {
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

            // MẬT KHẨU – chỉnh sửa trực tiếp, CHẶN space khi gõ
            HStack(spacing: 12) {
                Text("Mật khẩu")
                    .foregroundColor(.primary)
                    .frame(width: labelWidth, alignment: .leading)

                TextField("", text: $pwDraft, prompt: Text("Mật khẩu"))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textContentType(.password)
                    .keyboardType(.asciiCapable)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    // CHẶN space ngay khi gõ
                    .onChange(of: pwDraft) { newVal in
                        let cleaned = newVal.filter { !$0.isWhitespace }
                        if cleaned != newVal { pwDraft = cleaned }
                        item.password = cleaned.isEmpty ? nil : cleaned
                    }
            }
            .padding(.vertical, 2)
            // Ấn đè -> menu hệ thống "Sao chép"
            .contextMenu {
                let pwd = (item.password ?? "")
                if !pwd.isEmpty {
                    Button {
                        UIPasteboard.general.string = pwd
                        copied = true
                    } label: {
                        Label("Sao chép", systemImage: "doc.on.doc")
                    }
                }
            }

        } header: {
            Text("THÔNG TIN")
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var securitySection: some View {
        Section {
            NavigationLink {
                SecurityPickerView(security: $item.security, privacy: $item.macPrivacy)
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

    private var qrSection: some View {
        Section {
            // kích thước như trước – KHÔNG viền trong
            let maxW = UIScreen.main.bounds.width
            let size = min(maxW - 56, 320)

            VStack {
                QRCodeView(text: item.wifiQRString)
                    .frame(width: size, height: size)
                    .padding(14)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        } header: {
            Text("MÃ QR")
                .textCase(.uppercase)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Toolbar menu

    private var topMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let url = QRExport(imageText: item.wifiQRString)
                    .makeTempFile(named: "WiFi-QR-\(item.ssid).png") {
                    ShareLink(item: url) {
                        Label("Chia sẻ QR", systemImage: "square.and.arrow.up")
                    }
                }
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Xóa", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

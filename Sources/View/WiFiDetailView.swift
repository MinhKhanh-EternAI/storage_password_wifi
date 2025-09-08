import SwiftUI
import UIKit

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false
    @State private var copied = false
    @State private var savedToast = false

    // Soạn thảo mật khẩu (chặn space khi gõ)
    @State private var pwDraft: String = ""

    // Quản lý focus để ẩn bàn phím cho cả tên & mật khẩu
    private enum Field { case ssid, password }
    @FocusState private var focusedField: Field?

    var body: some View {
        List {
            infoSection
            securitySection
            qrSection
        }
        .onAppear { pwDraft = item.password ?? "" }
        // Tap/scroll là ẩn bàn phím
        .scrollDismissesKeyboard(.immediately)
        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
        // Vuốt từ mép trái để "Trở về" (kể cả khi dùng back tuỳ biến)
        .background(EnableSwipeBack())
        .navigationTitle(item.ssid.isEmpty ? "Wi-Fi" : item.ssid)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Nút “Trở về”
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
            Button("Xóa", role: .destructive) { store.delete(item.id); dismiss() }
        }
        // Toasts
        .toast(isPresented: $copied, text: "Đã sao chép mật khẩu")
        .toast(isPresented: $savedToast, text: "Đã lưu thành công")
        // Nút Lưu cố định dưới
        .safeAreaInset(edge: .bottom) {
            Button {
                // Ẩn bàn phím trước khi lưu
                hideKeyboard()

                if (item.password ?? "").isEmpty { item.security = .none }
                store.upsert(item)
                savedToast = true
            } label: {
                Text("Lưu thông tin")
                .fontWeight(.bold)
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
                    .focused($focusedField, equals: .ssid)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
            .padding(.vertical, 2)

            // NEW: BSSID (chỉ hiển thị nếu có)
            if let b = item.bssid, !b.isEmpty {
                HStack(spacing: 12) {
                    Text("BSSID")
                        .foregroundColor(.primary)
                        .frame(width: labelWidth, alignment: .leading)

                    Text(b)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                }
                .padding(.vertical, 2)
            }

            // MẬT KHẨU — TextField chỉnh sửa như soạn text + icon copy bên phải
            HStack(spacing: 12) {
                Text("Mật khẩu")
                    .foregroundColor(.primary)
                    .frame(width: labelWidth, alignment: .leading)

                ZStack(alignment: .trailing) {
                    TextField("", text: $pwDraft, prompt: Text("Mật khẩu"))
                        .focused($focusedField, equals: .password)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .keyboardType(.asciiCapable)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                        .padding(.trailing, 36)
                        .submitLabel(.done)
                        .onSubmit { hideKeyboard() }
                        .onChange(of: pwDraft) { newVal in
                            let cleaned = newVal.filter { !$0.isWhitespace }
                            if cleaned != newVal { pwDraft = cleaned }
                            item.password = cleaned.isEmpty ? nil : cleaned
                        }

                    Button {
                        let pwd = item.password ?? ""
                        if !pwd.isEmpty {
                            UIPasteboard.general.string = pwd
                            copied = true
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .imageScale(.medium)
                            .padding(.trailing, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)

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
                    Text(item.security.rawValue).foregroundColor(.secondary)
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
            // giữ kích thước – KHÔNG viền trong
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

    // MARK: - Toolbar (More)

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

    // MARK: - Helpers

    @MainActor
    private func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

// Cho phép vuốt mép trái để “Trở về” khi dùng NavigationStack + nút back tuỳ biến
private struct EnableSwipeBack: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            vc.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

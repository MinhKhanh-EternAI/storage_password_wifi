import SwiftUI
import UIKit

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var item: WiFiNetwork
    @State private var showDeleteAlert = false

    @State private var pwDraft: String = ""

    // 🔔 Banner (chỉ dùng cho các hành vi trong view này)
    @State private var showBanner = false
    @State private var lastSuccess = false
    @State private var lastMessage: String? = nil

    private enum Field { case ssid, password }
    @FocusState private var focusedField: Field?

    var body: some View {
        List {
            infoSection
            securitySection
            qrSection
        }
        .onAppear { pwDraft = item.password ?? "" }
        .scrollDismissesKeyboard(.immediately)
        .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
        .background(EnableSwipeBack())
        .navigationTitle(item.ssid.isEmpty ? "Wi-Fi" : item.ssid)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        // Chỉ icon chevron.left bold (Yêu cầu 8)
                        Image(systemName: "chevron.left").fontWeight(.bold)
                        Text("Trở về")
                    }
                }
            }
            topMenu
        }
        .alert("Bạn có chắc chắn muốn xóa?", isPresented: $showDeleteAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                let ssid = item.ssid
                store.delete(item.id)
                // Không hiển thị banner tại đây; gửi về ContentView để hiện
                NotificationCenter.default.post(name: .wifiDeleted, object: nil, userInfo: ["ssid": ssid])
                dismiss()
            }
        }

        // 🔔 Banner overlay — đặt giống ContentView (bên dưới status bar, đè lên nội dung)
        .overlay {
            GeometryReader { proxy in
                if showBanner {
                    BannerView(success: lastSuccess, count: 0, message: lastMessage)
                        .padding(.top, proxy.safeAreaInsets.top + 6) // đẩy xuống dưới đồng hồ (fix ảnh 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { withAnimation { showBanner = false } }
                        .gesture(DragGesture(minimumDistance: 10).onEnded { v in
                            if v.translation.height < 0 { withAnimation { showBanner = false } }
                        })
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showBanner = false }
                            }
                        }
                        .zIndex(999)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                hideKeyboard()
                if (item.password ?? "").isEmpty { item.security = .none }
                store.upsert(item)
                // Giữ banner khi bấm "Lưu thông tin" tại Detail (không đổi)
                showBannerResult(success: true, message: "Đã lưu thông tin Wi-Fi")
            } label: {
                Text("Lưu thông tin").fontWeight(.bold).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .environment(\.locale, Locale(identifier: "vi"))
    }

    // MARK: - Sections

    private var infoSection: some View {
        Section {
            let labelWidth: CGFloat = 92
            HStack(spacing: 12) {
                Text("Tên").frame(width: labelWidth, alignment: .leading)
                TextField("", text: $item.ssid, prompt: Text("Tên mạng"))
                    .focused($focusedField, equals: .ssid)
                    .textInputAutocapitalization(.never).disableAutocorrection(true)
            }
            .padding(.vertical, 2)

            if let b = item.bssid, !b.isEmpty {
                HStack(spacing: 12) {
                    Text("BSSID").frame(width: labelWidth, alignment: .leading)
                    Text(b).foregroundColor(.secondary)
                }.padding(.vertical, 2)
            }

            HStack(spacing: 12) {
                Text("Mật khẩu").frame(width: labelWidth, alignment: .leading)
                ZStack(alignment: .trailing) {
                    TextField("", text: $pwDraft, prompt: Text("Mật khẩu"))
                        .focused($focusedField, equals: .password)
                        .textInputAutocapitalization(.never).disableAutocorrection(true)
                        .textContentType(.password).keyboardType(.asciiCapable)
                        .onChange(of: pwDraft) { newVal in
                            let cleaned = newVal.filter { !$0.isWhitespace }
                            if cleaned != newVal { pwDraft = cleaned }
                            item.password = cleaned.isEmpty ? nil : cleaned
                        }
                        .padding(.trailing, 36)

                    Button {
                        let pwd = item.password ?? ""
                        if !pwd.isEmpty {
                            UIPasteboard.general.string = pwd
                            showBannerResult(success: true, message: "Đã sao chép mật khẩu")
                        }
                    } label: {
                        Image(systemName: "doc.on.doc").padding(.trailing, 4)
                    }.buttonStyle(.plain)
                }
            }.padding(.vertical, 2)
        } header: {
            Text("THÔNG TIN").textCase(.uppercase).font(.footnote).foregroundColor(.secondary)
        }
    }

    private var securitySection: some View {
        Section {
            NavigationLink {
                SecurityPickerView(security: $item.security, privacy: $item.macPrivacy)
            } label: {
                HStack { Text("Bảo mật"); Spacer(); Text(item.security.rawValue).foregroundColor(.secondary) }
            }
        } header: {
            Text("BẢO MẬT").textCase(.uppercase).font(.footnote).foregroundColor(.secondary)
        }
    }

    private var qrSection: some View {
        Section {
            let maxW = UIScreen.main.bounds.width
            let size = min(maxW - 56, 320)
            VStack {
                QRCodeView(text: item.wifiQRString).frame(width: size, height: size).padding(14)
            }.frame(maxWidth: .infinity).padding(.vertical, 6)
        } header: {
            Text("MÃ QR").textCase(.uppercase).font(.footnote).foregroundColor(.secondary)
        }
    }

    // MARK: - Toolbar

    private var topMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let url = QRExport(imageText: item.wifiQRString).makeTempFile(named: "WiFi-QR-\(item.ssid).png") {
                    ShareLink(item: url) { Label("Chia sẻ QR", systemImage: "square.and.arrow.up") }
                }
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Label("Xóa", systemImage: "trash")
                }
            } label: { Image(systemName: "ellipsis.circle") }
        }
    }

    // MARK: - Helpers

    private func showBannerResult(success: Bool, message: String) {
        lastSuccess = success
        lastMessage = message
        withAnimation { showBanner = true }
    }

    @MainActor private func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

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

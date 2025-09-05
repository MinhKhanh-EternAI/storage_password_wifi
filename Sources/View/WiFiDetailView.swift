import SwiftUI

struct WiFiDetailView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    @State var network: WiFiNetwork
    @State private var showEdit = false
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                QRCodeView(text: network.wifiQRString)
                    .frame(width: 180, height: 180)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: Rectangle())

                infoCard
            }
            .padding(16)
        }
        .navigationTitle(network.ssid)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        UIPasteboard.general.string = network.password
                        copied = true
                    } label: { Label("Sao chép mật khẩu", systemImage: "doc.on.doc") }

                    Button {
                        showEdit = true
                    } label: { Label("Sửa", systemImage: "pencil") }

                    Button(role: .destructive) {
                        store.delete(network); dismiss()
                    } label: { Label("Xóa", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) {
            WiFiFormView(mode: .edit(network)).environmentObject(store)
        }
        .toast(isPresented: $copied, text: "Đã sao chép mật khẩu")
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledValue("Tên mạng", network.ssid)
            LabeledValue("Mật khẩu", masked: network.password) {
                UIPasteboard.general.string = network.password
                copied = true
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct LabeledValue: View {
    let title: String
    var value: String? = nil
    var maskedValue: String? = nil
    var onLongPress: (() -> Void)?

    init(_ title: String, _ value: String) { self.title = title; self.value = value }
    init(_ title: String, masked: String, onLongPress: (() -> Void)? = nil) {
        self.title = title; self.maskedValue = masked; self.onLongPress = onLongPress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            HStack {
                if let value { Text(value).font(.headline) }
                if let maskedValue {
                    Text(String(repeating: "•", count: max(4, maskedValue.count)))
                        .font(.headline)
                        .onLongPressGesture(minimumDuration: 0.4) { onLongPress?() }
                }
                Spacer()
            }
        }
    }
}

private extension View {
    func toast(isPresented: Binding<Bool>, text: String) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                Text(text).padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                            withAnimation { isPresented.wrappedValue = false }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: isPresented.wrappedValue)
    }
}

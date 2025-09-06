import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    let duration: Double

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    Text(text)
                        .font(.callout)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut, value: isPresented)
    }
}

extension View {
    /// Hiển thị toast đơn giản ở trên cùng màn hình
    func toast(isPresented: Binding<Bool>, text: String, duration: Double = 1.5) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, text: text, duration: duration))
    }
}

import SwiftUI

private struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                Text(text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.85))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { isPresented = false }
                        }
                    }
                    .zIndex(1)
            }
        }
        .animation(.easeInOut, value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, text: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, text: text))
    }
}

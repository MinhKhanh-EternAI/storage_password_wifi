import SwiftUI

struct AppTheme {
    static let corner: CGFloat = 16

    static func card() -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color(.secondarySystemBackground))
    }
}

extension View {
    func sectionCard() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.corner, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}

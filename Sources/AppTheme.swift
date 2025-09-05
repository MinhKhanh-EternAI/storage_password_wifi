import SwiftUI

final class AppTheme: ObservableObject {
    enum Appearance: String, CaseIterable, Identifiable {
        case system = "Theo hệ thống"
        case light = "Sáng"
        case dark = "Tối"
        var id: String { rawValue }
        var label: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark:  return .dark
            }
        }
    }

    @Published var appearance: Appearance = .system
}

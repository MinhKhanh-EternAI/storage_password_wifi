import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var display: String {
        switch self {
        case .system: return "Hệ thống"
        case .light: return "Sáng"
        case .dark: return "Tối"
        }
    }
}

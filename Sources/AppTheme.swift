import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "Hệ thống"
    case light = "Sáng"
    case dark  = "Tối"
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("ThemeMode") var mode: ThemeMode = .system {
        didSet { objectWillChange.send() }
    }
    var overrideColorScheme: ColorScheme? { mode.colorScheme }
}

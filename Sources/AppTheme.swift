import SwiftUI

final class AppTheme: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
    }

    @AppStorage("theme_mode") private var stored: String = Mode.system.rawValue {
        didSet { objectWillChange.send() }
    }

    var mode: Mode {
        get { Mode(rawValue: stored) ?? .system }
        set { stored = newValue.rawValue }
    }

    var colorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct ThemePickerButton: View {
    @EnvironmentObject var theme: AppTheme

    private var icon: String {
        switch theme.mode {
        case .system: return "circle.lefthalf.filled" // icon hệ thống
        case .light:  return "sun.max"
        case .dark:   return "moon"
        }
    }

    var body: some View {
        Menu {
            Button("Hệ thống") { theme.mode = .system }
            Button("Sáng")     { theme.mode = .light }
            Button("Tối")      { theme.mode = .dark }
        } label: {
            Image(systemName: icon)
        }
    }
}

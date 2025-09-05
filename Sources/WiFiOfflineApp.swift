import SwiftUI

@main
struct WiFiOfflineApp: App {
    @StateObject private var store = WiFiStore()
    @StateObject private var theme = AppTheme()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(theme)
                .preferredColorScheme({
                    switch theme.appearance {
                    case .system: return nil
                    case .light:  return .light
                    case .dark:   return .dark
                    }
                }())
        }
    }
}

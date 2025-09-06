import SwiftUI

@main
struct WiFiOfflineApp: App {
    @StateObject private var store = WiFiStore()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(theme)
                .preferredColorScheme(theme.overrideColorScheme)
        }
    }
}

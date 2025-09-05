import SwiftUI

@main
struct WiFiOfflineApp: App {
    @StateObject var theme = AppTheme()
    @StateObject var store = WiFiStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
                .environmentObject(store)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}

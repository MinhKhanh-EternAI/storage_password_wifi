import SwiftUI

@main
struct WiFiOfflineApp: App {
    @AppStorage("appearance") private var appearanceRaw: String = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    (AppearanceMode(rawValue: appearanceRaw) ?? .system).scheme
                )
        }
    }
}

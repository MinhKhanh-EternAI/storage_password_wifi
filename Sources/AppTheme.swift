import SwiftUI

final class AppTheme: ObservableObject {
    @AppStorage("theme") var theme: Int = 0 // 0: Tự động, 1: Sáng, 2: Tối
    var colorScheme: ColorScheme? { theme == 0 ? nil : (theme == 1 ? .light : .dark) }
}

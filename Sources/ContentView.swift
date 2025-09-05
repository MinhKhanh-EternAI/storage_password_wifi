import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi")
                .imageScale(.large)
                .font(.system(size: 40))
            Text("WiFiOffline (Unsigned)")
                .font(.headline)
            Text("App mẫu để CI tạo .ipa hợp lệ (eSign đọc được).")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

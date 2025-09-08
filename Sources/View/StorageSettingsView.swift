import SwiftUI

struct StorageSettingsView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Lưu trữ") {
                    Toggle("Lưu trong Bộ nhớ trên iPhone", isOn: Binding(
                        get: { store.allowLocalStorage },
                        set: { store.setAllowLocalStorage($0) }
                    ))
                    Toggle("Sao lưu lên iCloud Drive", isOn: Binding(
                        get: { store.allowICloudStorage },
                        set: { store.setAllowICloudStorage($0) }
                    ))
                }

                Section(footer: Text("Bạn có thể thay đổi lựa chọn bất kỳ lúc nào.")) { EmptyView() }
            }
            .navigationTitle("Quyền lưu trữ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
}

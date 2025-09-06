import SwiftUI

enum FormMode {
    case create
    case edit
}

struct WiFiFormView: View {
    @Environment(\.dismiss) private var dismiss
    let mode: FormMode
    @State private var model: WiFiNetwork
    let onSave: (WiFiNetwork) -> Void

    init(mode: FormMode, item: WiFiNetwork, onSave: @escaping (WiFiNetwork) -> Void) {
        self.mode = mode
        self._model = State(initialValue: item)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin") {
                    TextField("Tên mạng", text: $model.ssid)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    SecureField("Mật khẩu", text: Binding(
                        get: { model.password ?? "" },
                        set: { model.password = $0.isEmpty ? nil : $0 }
                    ))

                    Picker("Bảo mật", selection: $model.security) {
                        ForEach(SecurityType.allCases) { sec in
                            Text(sec.displayName).tag(sec)
                        }
                    }
                }
            }
            .navigationTitle(mode == .create ? "Thêm mạng" : "Sửa Wi-Fi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") {
                        onSave(model)
                    }
                    .disabled(model.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

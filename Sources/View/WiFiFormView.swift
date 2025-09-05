import SwiftUI

struct WiFiFormView: View {
    enum Mode { case add(WiFiNetwork), edit(WiFiNetwork) }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: WiFiStore

    let mode: Mode
    @State private var model: WiFiNetwork
    @State private var showSecurity = false
    @State private var showPrivate = false

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add(let draft): _model = State(initialValue: draft)
        case .edit(let existed): _model = State(initialValue: existed)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("THÔNG TIN CƠ BẢN") {
                    TextField("Tên mạng", text: $model.ssid)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Mật khẩu", text: $model.password)

                    // Bảo mật: chỉ text ở ngoài, tick sẽ xuất hiện TRONG menu
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(model.security.display).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showSecurity = true }
                    .confirmationDialog("Bảo mật", isPresented: $showSecurity, titleVisibility: .visible) {
                        ForEach(WiFiSecurity.allCases, id: \.self) { sec in
                            Button {
                                model.security = sec
                            } label: {
                                HStack {
                                    Text(sec.display)
                                    if sec == model.security { Spacer(); Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }

                    HStack {
                        Text("Địa chỉ Wi-Fi bảo mật")
                        Spacer()
                        Text(model.privateAddress.display).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showPrivate = true }
                    .confirmationDialog("Địa chỉ Wi-Fi bảo mật", isPresented: $showPrivate, titleVisibility: .visible) {
                        ForEach(PrivateAddress.allCases, id: \.self) { opt in
                            Button {
                                model.privateAddress = opt
                            } label: {
                                HStack {
                                    Text(opt.display)
                                    if opt == model.privateAddress { Spacer(); Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") { save() }.bold()
                        .disabled(model.ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var modeTitle: String { switch mode { case .add: "Thêm Wi-Fi"; case .edit: "Sửa Wi-Fi" } }

    private func save() {
        switch mode {
        case .add: store.add(model)
        case .edit: store.update(model)
        }
        dismiss()
    }
}

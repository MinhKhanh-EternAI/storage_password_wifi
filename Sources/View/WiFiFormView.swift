import SwiftUI

enum FormMode {
    case create
    case edit
}

struct WiFiFormView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.dismiss) var dismiss
    
    let mode: FormMode
    @State var item: WiFiNetwork
    
    @State private var showSecurity = false
    @State private var showMacPolicy = false
    
    var body: some View {
        Form {
            Section(header: Text("THÔNG TIN")) {
                TextField("Tên", text: $item.ssid)
                SecureField("Mật khẩu", text: Binding(
                    get: { item.password ?? "" },
                    set: { item.password = $0 }
                ))
            }
            
            Section(header: Text("BẢO MẬT")) {
                Button {
                    showSecurity = true
                } label: {
                    HStack {
                        Text("Bảo mật")
                        Spacer()
                        Text(item.security.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(mode == .create ? "Thêm Wi-Fi" : "Sửa Wi-Fi")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {   // 👈 wrap trong ToolbarItemGroup
                Button("Hủy") { dismiss() }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Lưu") {
                    if mode == .create {
                        store.add(item)
                    } else {
                        store.upsert(item)   // 👈 đồng bộ với WiFiDetailView
                    }
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showSecurity) {
            SecurityPickerView(selected: $item.security)
        }
    }
}

struct SecurityPickerView: View {
    @Binding var selected: SecurityType
    
    var body: some View {
        List {
            ForEach(SecurityType.allCases, id: \.self) { type in
                HStack {
                    Text(type.rawValue)
                    Spacer()
                    if type == selected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selected = type
                }
            }
        }
        .navigationTitle("Bảo mật")
    }
}

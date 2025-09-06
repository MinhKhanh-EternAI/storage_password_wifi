import SwiftUI
import UniformTypeIdentifiers   // cần cho UTType.json khi import/export

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.colorScheme) private var scheme

    @State private var searchText: String = ""
    @State private var showImportSheet = false
    @State private var showExportSheet = false

    var body: some View {
        NavigationStack {
            List {
                // MẠNG HIỆN TẠI
                Section("MẠNG HIỆN TẠI") {
                    HStack {
                        Text(store.currentSSID ?? "Wifi Hiện tại")
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            // tạo bản ghi mới từ SSID hiện tại
                            store.prepareAddCurrent()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // ĐÃ LƯU
                Section("ĐÃ LƯU") {
                    if store.items.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "wifi.slash")
                            Text("Chưa có mạng nào được lưu")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(store.filteredItems(searchText)) { net in
                            NavigationLink {
                                WiFiDetailView(item: net)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(net.ssid)
                                            .fontWeight(.semibold)
                                        if let pwd = net.password, !pwd.isEmpty {
                                            Text(String(repeating: "•", count: max(6, pwd.count)))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right") // mũi tên
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    confirmDelete(net)
                                } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Wi-Fi")
            .toolbar {
                // icon chủ đề: mặt trời/mặt trăng
                ToolbarItem(placement: .topBarLeading) {
                    ThemePickerButton()
                }
                // dấu cộng (thêm thủ công)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.prepareAddManual()
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
                // dấu ba chấm: Nhập / Xuất
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showImportSheet = true
                        } label: {
                            Label("Nhập danh sách", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            showExportSheet = true
                        } label: {
                            Label("Xuất danh sách", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            // ô tìm kiếm ở cuối màn hình (kéo/ẩn tuỳ ý: đơn giản là đặt ở .safeAreaInset bottom)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
        }
        // mở form tạo/sửa — KHÔNG truyền onSave nữa
        .sheet(isPresented: $store.presentForm) {
            NavigationStack {
                WiFiFormView(
                    mode: store.editing == nil ? .create : .edit,
                    item: store.editing ?? store.fallbackNewItem()
                )
                .environmentObject(store)
            }
        }
        // Import JSON
        .fileImporter(isPresented: $showImportSheet,
                      allowedContentTypes: [.json],
                      allowsMultipleSelection: false) { result in
            store.handleImport(result: result)
        }
        // Export JSON
        .fileExporter(isPresented: $showExportSheet,
                      document: store.exportDocument(),
                      contentType: .json,
                      defaultFilename: "wifi_store") { result in
            store.handleExport(result: result)
        }
    }

    // Xác nhận xóa
    private func confirmDelete(_ item: WiFiNetwork) {
        store.confirmDelete(item)
    }
}

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @Environment(\.colorScheme) private var scheme

    @State private var searchText: String = ""
    @State private var showImportSheet = false
    @State private var showExportSheet = false

    // xác nhận xoá
    @State private var pendingDelete: WiFiNetwork?

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
                            // nếu trong Store có luồng tạo nhanh thì gọi;
                            // nếu không có, sheet thêm thủ công sẽ được mở ở dấu cộng phía trên
                            store.prepareAddCurrent?()
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
                        ForEach(store.filteredItems?(searchText) ?? store.items) { net in
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
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    pendingDelete = net
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
                // Dấu cộng (thêm thủ công)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.prepareAddManual?()    // nếu không có method này, không sao
                        store.presentForm = true     // sheet hiển thị form (được store hay view tự xử lý)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }

                // Dấu ba chấm: Nhập / Xuất
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
        }
        // mở form (Form tự gọi store.upsert khi bấm Lưu)
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
            store.handleImport?(result)
        }
        // Export JSON
        .fileExporter(isPresented: $showExportSheet,
                      document: store.exportDocument?() ?? WiFiJSONDocument(networks: store.items),
                      contentType: .json,
                      defaultFilename: "wifi_store") { result in
            store.handleExport?(result)
        }
        // hỏi xoá
        .alert("Xóa mạng Wi-Fi?", isPresented: .constant(pendingDelete != nil), presenting: pendingDelete) { item in
            Button("Hủy", role: .cancel) { pendingDelete = nil }
            Button("Chắc chắn", role: .destructive) {
                if let idx = store.items.firstIndex(of: item) {
                    store.items.remove(at: idx)
                    store.persist?()        // nếu Store có hàm lưu, sẽ được gọi
                }
                pendingDelete = nil
            }
        } message: { item in
            Text("Bạn có chắc chắn muốn xóa “\(item.ssid)”?")
        }
    }
}

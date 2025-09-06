import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore
    @EnvironmentObject var current: CurrentWiFi
    @AppStorage("theme") private var theme: AppTheme = .system

    @State private var query = ""
    @State private var showDeleteAlert = false
    @State private var itemToDelete: WiFiNetwork? = nil
    @State private var showImportExport = false
    @State private var showFileImporter = false
    @State private var showFileExporter = false
    @State private var exportData: Data? = nil

    var body: some View {
        NavigationStack {
            VStack {
                // Current network
                Section(header: Text("Mạng hiện tại")) {
                    HStack {
                        Text(current.ssid ?? "Không xác định")
                            .bold()
                        Spacer()
                        Button("+") {
                            if let ssid = current.ssid {
                                store.editing = WiFiNetwork(ssid: ssid, password: nil)
                                store.presentForm = true
                            }
                        }
                    }
                }
                .padding()

                // Search bar
                TextField("Tìm kiếm Wi-Fi", text: $query)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                // Saved list
                List {
                    if store.items.isEmpty {
                        Label("Chưa có mạng nào được lưu", systemImage: "wifi.slash")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(filtered) { item in
                            NavigationLink(destination: WiFiDetailView(item: item)) {
                                HStack {
                                    Text(item.ssid)
                                    Spacer()
                                    Image(systemName: "qrcode")
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                    showDeleteAlert = true
                                } label: {
                                    Label("Xóa", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Wi-Fi")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(AppTheme.allCases) { t in
                            Button {
                                theme = t
                            } label: {
                                Label(t.display, systemImage: t.icon)
                            }
                        }
                    } label: {
                        Image(systemName: theme.icon)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            store.editing = nil
                            store.presentForm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        Menu {
                            Button("Nhập danh sách", systemImage: "square.and.arrow.down") {
                                showFileImporter = true
                            }
                            Button("Xuất danh sách", systemImage: "square.and.arrow.up") {
                                if let data = store.exportJSON() {
                                    exportData = data
                                    showFileExporter = true
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $store.presentForm) {
                WiFiFormView(
                    mode: store.editing == nil ? .create : .edit,
                    item: store.editing ?? .init(ssid: "", password: nil),
                    onSave: { model in store.upsert(model) }
                )
            }
            .alert("Bạn có chắc chắn muốn xóa?", isPresented: $showDeleteAlert) {
                Button("Chắc chắn", role: .destructive) {
                    if let item = itemToDelete { store.delete(item) }
                }
                Button("Hủy", role: .cancel) { }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result,
               let data = try? Data(contentsOf: url) {
                store.importJSON(data)
            }
        }
        .fileExporter(isPresented: $showFileExporter, document: JSONDocument(data: exportData ?? Data()), contentType: .json, defaultFilename: "wifi_store") { _ in }
    }

    var filtered: [WiFiNetwork] {
        if query.isEmpty { return store.items.sorted { $0.ssid < $1.ssid } }
        return store.items.filter { $0.ssid.localizedCaseInsensitiveContains(query) }
    }
}

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { .init(regularFileWithContents: data) }
}

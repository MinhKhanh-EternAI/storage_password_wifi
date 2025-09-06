import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: WiFiStore

    @State private var showingAdd = false
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDoc = WiFiJSONDocument(networks: [])

    var body: some View {
        NavigationStack {
            listView
                .navigationTitle("WiFi Offline")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            prepareExport()
                            showingExporter = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }

                        Button {
                            showingImporter = true
                        } label: {
                            Image(systemName: "tray.and.arrow.down")
                        }

                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
        // Export JSON
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDoc,
            contentType: .json,
            defaultFilename: "wifi_networks.json",
            onCompletion: { _ in }
        )
        // Import JSON
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result)
        }
        // Thêm mới
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                WiFiFormView(
                    mode: .create,
                    item: newItem()
                )
                .environmentObject(store)
            }
        }
    }

    // MARK: - Subviews

    private var listView: some View {
        List {
            if store.items.isEmpty {
                emptyState
            } else {
                ForEach(store.items) { network in
                    NavigationLink {
                        WiFiDetailView(item: network)
                            .environmentObject(store)
                    } label: {
                        row(for: network)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.secondary)
            Text("Chưa có mạng nào")
                .foregroundStyle(.secondary)
            Text("Nhấn nút “+” để thêm mạng Wi-Fi.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 32)
        .listRowBackground(Color.clear)
    }

    private func row(for item: WiFiNetwork) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ssid)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(item.security.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let pwd = item.password, !pwd.isEmpty {
                        Text("• Có mật khẩu")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("• Mở")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func deleteItems(at offsets: IndexSet) {
        // Xoá item khỏi store (đa số Store sẽ tự persist trong didSet)
        for index in offsets {
            let id = store.items[index].id
            store.items.removeAll { $0.id == id }
        }
    }

    private func newItem() -> WiFiNetwork {
        WiFiNetwork(
            id: UUID(),
            ssid: "",
            password: nil,
            security: SecurityType.allCases.first ?? SecurityType.allCases[0]
        )
    }

    private func prepareExport() {
        // Giữ hook cũ nếu Store đã có
        if let maker = store.exportDocument {
            exportDoc = maker()
        } else {
            exportDoc = WiFiJSONDocument(networks: store.items)
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            // Merge đơn giản: thêm mới, cập nhật trùng id
            var map = Dictionary(uniqueKeysWithValues: store.items.map { ($0.id, $0) })
            for n in imported { map[n.id] = n }
            store.items = Array(map.values)
                .sorted { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending }
        } catch {
            // Có thể thêm thông báo lỗi UI nếu cần
            print("Import failed: \(error)")
        }
    }
}

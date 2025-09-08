import Foundation
import Combine

final class WiFiStore: ObservableObject {
    // MARK: - State

    @Published var items: [WiFiNetwork] = [] {
        didSet { persistToDisk() }
    }

    /// SSID đang kết nối (hiển thị ở "Mạng hiện tại")
    @Published var currentSSID: String?

    // Backup key cũ (migrate từ UserDefaults nếu có)
    private let legacyStorageKey = "WiFiStore.items.v1"

    // MARK: - Init

    init() {
        // Tạo sẵn thư mục
        WiFiFileSystem.ensureDirectories()
        // Ưu tiên khôi phục từ file; nếu chưa có, thử migrate từ UserDefaults
        if !restoreFromDisk() {
            restoreFromUserDefaultsAndWriteToDisk()
        }
        sortInPlace()
    }

    // MARK: - CRUD

    func upsert(_ item: WiFiNetwork) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
        sortInPlace()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func sortInPlace() {
        items.sort {
            $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending
        }
    }

    // MARK: - Persistence (File in Wi-Fi/Database)

    /// Ghi CSDL vào Wi-Fi/Database/wifi-database.json (local) và bản sao iCloud (nếu có)
    private func persistToDisk() {
        do {
            let data = try JSONEncoder.iso.encode(ExportFileV2(items: items))
            // Local
            try WiFiFileSystem.ensureDirectories()
            try data.write(to: WiFiFileSystem.localDatabaseFile, options: .atomic)

            // iCloud (nếu có)
            if let icDB = WiFiFileSystem.iCloudDatabaseFile {
                try data.write(to: icDB, options: .atomic)
            }
        } catch {
            print("Persist error:", error.localizedDescription)
        }
    }

    /// Khôi phục từ Wi-Fi/Database/wifi-database.json. Trả về true nếu đọc được.
    @discardableResult
    private func restoreFromDisk() -> Bool {
        do {
            let url = WiFiFileSystem.localDatabaseFile
            guard FileManager.default.fileExists(atPath: url.path) else { return false }
            let data = try Data(contentsOf: url)
            if let v2 = try? JSONDecoder().decode(ExportFileV2.self, from: data) {
                self.items = v2.items; return true
            }
            // fallback sang mảng thuần nếu là file rất cũ
            self.items = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            return true
        } catch {
            print("Restore error:", error.localizedDescription)
            return false
        }
    }

    /// Migrate dữ liệu cũ từ UserDefaults sang file
    private func restoreFromUserDefaultsAndWriteToDisk() {
        guard let data = UserDefaults.standard.data(forKey: legacyStorageKey) else { return }
        do {
            let old = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            self.items = old
            persistToDisk()
        } catch {
            print("Legacy restore error:", error.localizedDescription)
        }
    }

    // MARK: - Export snapshots (Wi-Fi/Export)

    struct ExportFileV2: Codable {
        let schemaVersion: Int = 2
        let exportedAt: Date = .now
        var items: [WiFiNetwork]
    }

    /// Xuất snapshot hiện tại vào Wi-Fi/Export (local + iCloud nếu có). Trả về URL file local.
    @discardableResult
    func exportSnapshot() throws -> URL {
        let fileName = WiFiFileSystem.makeTimestampedExportFileName()
        let localURL = WiFiFileSystem.localExportDir.appendingPathComponent(fileName)

        let payload = ExportFileV2(items: items)
        let data = try JSONEncoder.iso.encode(payload)

        try WiFiFileSystem.ensureDirectories()
        try data.write(to: localURL, options: .atomic)

        if let iCloudDir = WiFiFileSystem.iCloudExportDir {
            let icURL = iCloudDir.appendingPathComponent(fileName)
            try data.write(to: icURL, options: .atomic)
        }
        return localURL
    }

    // MARK: - Import (.json / .js / .txt) with merge by BSSID

    enum ImportError: Error {
        case invalidEncoding
        case invalidFormat
        case empty
    }

    /// Nhập dữ liệu từ URL (cho phép .json, .js, .txt).
    /// Format chấp nhận:
    ///   1) `[WiFiNetwork]`
    ///   2) `{ "items": [WiFiNetwork], ... }`
    func importFrom(url: URL) throws {
        let rawData = try Data(contentsOf: url)
        let ext = url.pathExtension.lowercased()

        // Nếu là .js / .txt: cố tách JSON thuần từ nội dung text
        let dataForDecode: Data
        if ["js", "txt"].contains(ext) {
            guard let text = String(data: rawData, encoding: .utf8) else {
                throw ImportError.invalidEncoding
            }
            let json = Self.extractJSON(from: text)
            guard let jsonData = json.data(using: .utf8) else {
                throw ImportError.invalidEncoding
            }
            dataForDecode = jsonData
        } else {
            dataForDecode = rawData
        }

        // Thử decode theo 2 schema
        let decoder = JSONDecoder()
        var imported: [WiFiNetwork]? = nil

        if let v2 = try? decoder.decode(ExportFileV2.self, from: dataForDecode) {
            imported = v2.items
        } else if let wrap = try? decoder.decode(WrapperAny.self, from: dataForDecode) {
            imported = wrap.items
        } else if let arr = try? decoder.decode([WiFiNetwork].self, from: dataForDecode) {
            imported = arr
        }

        guard let list = imported, !list.isEmpty else { throw ImportError.empty }

        mergeByBSSID(list)
        sortInPlace()
    }

    /// Wrapper "mềm" chỉ cần có trường items
    private struct WrapperAny: Codable { let items: [WiFiNetwork] }

    /// Hỗ trợ tách JSON từ text có thể chứa JS wrapper.
    /// Ưu tiên tìm `[...]`, nếu không có sẽ thử `{...}`.
    private static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first, first == "[" || first == "{" { return trimmed }
        if let s = trimmed.firstIndex(of: "["), let e = trimmed.lastIndex(of: "]"), s < e {
            return String(trimmed[s...e])
        }
        if let s = trimmed.firstIndex(of: "{"), let e = trimmed.lastIndex(of: "}"), s < e {
            return String(trimmed[s...e])
        }
        return trimmed
    }

    /// Merge dựa trên BSSID:
    /// - Nếu incoming có `bssid` (không rỗng) và trùng `bssid` của một bản ghi hiện có -> GHI ĐÈ (giữ nguyên id cũ).
    /// - Nếu incoming có `bssid` mới -> THÊM mới.
    /// - Nếu incoming không có `bssid` -> KHÔNG tác động (đúng theo yêu cầu: chỉ xét theo BSSID).
    private func mergeByBSSID(_ incoming: [WiFiNetwork]) {
        var indexByBSSID: [String: Int] = [:]
        for (i, it) in items.enumerated() {
            if let b = it.bssid?.lowercased(), !b.isEmpty {
                indexByBSSID[b] = i
            }
        }

        for var nw in incoming {
            guard let bss = nw.bssid?.lowercased(), !bss.isEmpty else {
                // yêu cầu: bỏ qua record không có BSSID
                continue
            }
            if let idx = indexByBSSID[bss] {
                // Ghi đè: giữ id cũ để ổn định UI
                nw.id = items[idx].id
                items[idx] = nw
            } else {
                items.append(nw)
            }
        }
        persistToDisk()
    }
}

// MARK: - JSON helpers

private extension JSONEncoder {
    static var iso: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }
}

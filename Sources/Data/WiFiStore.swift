import Foundation
import Combine

final class WiFiStore: ObservableObject {
    // MARK: - State

    @Published var items: [WiFiNetwork] = [] {
        didSet { persist() }
    }

    /// SSID đang kết nối (hiển thị ở "Mạng hiện tại")
    @Published var currentSSID: String?

    // MARK: - Storage key

    private let storageKey = "WiFiStore.items.v1"

    // MARK: - Init

    init() {
        restore()
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

    // MARK: - Persistence (UserDefaults)

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Persist error:", error.localizedDescription)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            items = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            sortInPlace()
        } catch {
            print("Restore error:", error.localizedDescription)
        }
    }

    // MARK: - Import (.json / .js / .txt)

    enum ImportError: Error {
        case invalidEncoding
        case invalidFormat
        case empty
    }

    /// Nhập dữ liệu từ URL (cho phép .json, .js, .txt).
    /// - Hỗ trợ nội dung dạng:
    ///   1) `[WiFiNetwork]`
    ///   2) `{ "items": [WiFiNetwork] }`
    ///   3) File .js có wrapper kiểu `const data = [...]` hoặc `export default [...]`
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
        var imported: [WiFiNetwork]?

        // 1) Mảng thuần
        if let arr = try? decoder.decode([WiFiNetwork].self, from: dataForDecode) {
            imported = arr
        } else {
            // 2) Bọc trong đối tượng
            struct Wrapper: Codable { let items: [WiFiNetwork] }
            if let wrap = try? decoder.decode(Wrapper.self, from: dataForDecode) {
                imported = wrap.items
            }
        }

        guard let list = imported, !list.isEmpty else {
            throw ImportError.empty
        }

        // Merge vào danh sách đang có
        merge(list)
        sortInPlace()
    }

    /// Hỗ trợ tách JSON từ text có thể chứa JS wrapper.
    /// Ưu tiên tìm `[...]`, nếu không có sẽ thử `{...}`.
    private static func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Nếu đã là JSON thuần
        if let first = trimmed.first, first == "[" || first == "{" {
            return trimmed
        }
        // Tìm mảng đầu tiên
        if let s = trimmed.firstIndex(of: "["),
           let e = trimmed.lastIndex(of: "]"),
           s < e {
            return String(trimmed[s...e])
        }
        // Tìm object đầu tiên
        if let s = trimmed.firstIndex(of: "{"),
           let e = trimmed.lastIndex(of: "}"),
           s < e {
            return String(trimmed[s...e])
        }
        return trimmed // để bước decode báo lỗi nếu không hợp lệ
    }

    /// Gộp danh sách mới vào `items`.
    /// - Ưu tiên trùng `id`.
    /// - Nếu `id` khác nhưng `ssid` trùng (sau khi normalize) thì ghi đè theo `ssid`.
    func merge(_ incoming: [WiFiNetwork]) {
        var indexByID: [UUID: Int] = [:]
        var indexBySSID: [String: Int] = [:]

        for (i, it) in items.enumerated() {
            indexByID[it.id] = i
            indexBySSID[Self.norm(it.ssid)] = i
        }

        for nw in incoming {
            if let idx = indexByID[nw.id] {
                items[idx] = nw
            } else if let idx = indexBySSID[Self.norm(nw.ssid)] {
                items[idx] = nw
            } else {
                items.append(nw)
            }
        }
    }

    private static func norm(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

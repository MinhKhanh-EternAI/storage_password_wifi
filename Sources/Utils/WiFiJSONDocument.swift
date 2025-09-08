import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// Dùng cho fileImporter / fileExporter (định dạng JSON danh sách WiFiNetwork)
struct WiFiJSONDocument: FileDocument, Identifiable {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var id = UUID()
    var networks: [WiFiNetwork]

    // MARK: - Schema

    /// Schema v2 (mới)
    struct ExportFileV2: Codable {
        let schemaVersion: Int = 2
        let exportedAt: Date = .now
        var items: [WiFiNetwork]
    }

    /// Wrapper cũ có thể gặp (không đảm bảo có schemaVersion)
    private struct WrapperV1: Codable {
        var items: [WiFiNetwork]
    }

    // MARK: - Init

    init(networks: [WiFiNetwork]) {
        self.networks = networks
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()

        // Ưu tiên v2
        if let v2 = try? decoder.decode(ExportFileV2.self, from: data) {
            self.networks = v2.items
            return
        }

        // Thử wrapper V1
        if let wrap = try? decoder.decode(WrapperV1.self, from: data) {
            self.networks = wrap.items
            return
        }

        // Cuối cùng: mảng thuần [WiFiNetwork]
        self.networks = try decoder.decode([WiFiNetwork].self, from: data)
    }

    // MARK: - Write

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Luôn xuất theo schema v2
        let payload = ExportFileV2(items: networks)
        let data = try JSONEncoder.iso.encode(payload)
        return .init(regularFileWithContents: data)
    }
}

// MARK: - JSON helpers

private extension JSONEncoder {
    static var iso: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

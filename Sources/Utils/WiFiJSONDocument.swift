import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// Dùng cho fileImporter/fileExporter khi cần, linh hoạt nhiều schema.
struct WiFiJSONDocument: FileDocument, Identifiable {
    static var readableContentTypes: [UTType] { [.json, .data] }
    static var writableContentTypes: [UTType] { [.json] }

    var id = UUID()
    var networks: [WiFiNetwork]

    struct Payload: Codable {
        var schemaVersion: Int = 2   // <- var để hết warning
        var exportedAt: Date = Date()
        var items: [WiFiNetwork]
    }

    init(networks: [WiFiNetwork]) {
        self.networks = networks
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let dec = JSONDecoder()
        if let p = try? dec.decode(Payload.self, from: data) {
            self.networks = p.items
        } else if let arr = try? dec.decode([WiFiNetwork].self, from: data) {
            self.networks = arr
        } else if let wrap = try? dec.decode(Wrapper.self, from: data) {
            self.networks = wrap.items
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder.iso.encode(Payload(items: networks))
        return .init(regularFileWithContents: data)
    }

    private struct Wrapper: Codable { let items: [WiFiNetwork] }
}

private extension JSONEncoder {
    static var iso: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }
}

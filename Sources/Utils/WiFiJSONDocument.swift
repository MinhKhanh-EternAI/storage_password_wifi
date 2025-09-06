import Foundation
import UniformTypeIdentifiers
import SwiftUI

/// Dùng cho fileImporter / fileExporter (định dạng JSON danh sách WiFiNetwork)
struct WiFiJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var networks: [WiFiNetwork]

    init(networks: [WiFiNetwork]) {
        self.networks = networks
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.networks = try JSONDecoder().decode([WiFiNetwork].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(networks)
        return .init(regularFileWithContents: data)
    }
}

import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

/// Tạo ảnh QR và ghi ra file tạm để ShareLink(item: URL)
struct QRExport {
    let imageText: String

    /// Ghi PNG QR ra file tạm, trả về URL để dùng với ShareLink(item:)
    func makeTempFile(named filename: String? = nil) -> URL? {
        guard let data = Self.makeQRPNG(from: imageText) else { return nil }

        let name = (filename ?? "WiFi-QR-\(Self.safeFileName(from: imageText)).png")
            .replacingOccurrences(of: " ", with: "-")

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("qr_share", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(name)

        // Ghi đè nếu đã tồn tại
        try? FileManager.default.removeItem(at: url)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("QRExport write error:", error)
            return nil
        }
    }

    // MARK: - Helpers

    /// Tạo PNG data từ chuỗi QR (CIQRCodeGenerator)
    static func makeQRPNG(from string: String) -> Data? {
        let data = Data(string.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        // scale để nét hơn
        let scale: CGFloat = 10
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.pngData()
    }

    /// Tạo tên file an toàn từ chuỗi
    private static func safeFileName(from text: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return text.components(separatedBy: invalid).joined()
    }
}

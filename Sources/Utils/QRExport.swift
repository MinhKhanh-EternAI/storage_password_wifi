import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

/// Gói dữ liệu ảnh QR (PNG) để dùng với ShareLink
struct QRExport: Identifiable {
    let id = UUID()
    let pngData: Data
    let filename: String

    /// Khởi tạo từ chuỗi QR (ví dụ WIFI:... )
    /// - Parameters:
    ///   - imageText: Nội dung sẽ render thành mã QR
    ///   - filename: Tên gợi ý khi share/save
    init(imageText: String, filename: String = "wifi_qr.png") {
        self.pngData = QRExport.makeQRPNG(from: imageText) ?? Data()
        self.filename = filename
    }

    /// Tạo PNG từ chuỗi bằng Core Image (không phụ thuộc file QRCode.swift sẵn có)
    private static func makeQRPNG(from string: String) -> Data? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }

        // Phóng to mã QR cho nét (scale 10x)
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.pngData()
    }
}

/// Cho phép ShareLink xuất ra file PNG
extension QRExport: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { qr in
            qr.pngData
        }
        .suggestedFileName { $0.filename }
    }
}

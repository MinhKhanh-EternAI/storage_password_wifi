import SwiftUI
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins
import UIKit

/// Model dùng để chia sẻ ảnh QR qua ShareLink (iOS 16+) bằng Transferable
struct QRExport: Identifiable, Transferable {
    let id = UUID()
    let imageText: String
    let pngData: Data

    init(imageText: String) {
        self.imageText = imageText
        self.pngData = QRExport.makeQRPNG(from: imageText) ?? Data()
    }

    // Cho phép ShareLink xuất dữ liệu PNG từ QRExport
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.pngData
        }
        .previewDisplayName(Text("Mã QR Wi-Fi"))
    }

    /// Tạo ảnh PNG mã QR từ chuỗi (dùng CIQRCodeGenerator)
    static func makeQRPNG(from string: String) -> Data? {
        let data = Data(string.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // H/L/M/Q

        guard let outputImage = filter.outputImage else { return nil }

        // Scale để ảnh nét hơn
        let scale: CGFloat = 10
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.pngData()
    }
}

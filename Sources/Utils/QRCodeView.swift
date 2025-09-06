import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

// Hàm tạo UIImage từ chuỗi
func qrImage(from string: String, scale: CGFloat = 12) -> UIImage {
    let data = Data(string.utf8)
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.setValue(data, forKey: "inputMessage")
    filter.correctionLevel = "M" // độ bền QR: L/M/Q/H

    let transform = CGAffineTransform(scaleX: scale, y: scale)
    if let output = filter.outputImage?.transformed(by: transform),
       let cg = context.createCGImage(output, from: output.extent) {
        return UIImage(cgImage: cg)
    }
    return UIImage()
}

// View hiển thị QR từ chuỗi text thường
struct QRCodeView: View {
    let text: String

    var body: some View {
        let uiImage = qrImage(from: text, scale: 12)
        return Image(uiImage: uiImage)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 1)
            .accessibilityLabel(Text("Mã QR Wi-Fi"))
    }
}

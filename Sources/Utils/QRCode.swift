import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let text: String
    let size: CGFloat

    var body: some View {
        Image(uiImage: qrImage(text: text, size: size))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 6)
    }

    private func qrImage(text: String, size: CGFloat) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M" // L/M/Q/H

        let transform = CGAffineTransform(scaleX: size/128, y: size/128)
        let output = filter.outputImage?.transformed(by: transform) ?? CIImage(color: .white)
        if let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return UIImage()
    }
}

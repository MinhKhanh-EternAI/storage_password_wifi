import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let text: String
    let size: CGFloat

    var body: some View {
        ZStack {
            // Khung vuông
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2))
                .foregroundStyle(.primary)
                .frame(width: size + 20, height: size + 20)

            Image(uiImage: UIImage.qr(from: text, size: Int(size)))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
        .accessibilityLabel("Mã QR Wi-Fi")
    }
}

extension UIImage {
    static func qr(from string: String, size: Int) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(string.data(using: .utf8), forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: CGFloat(size)/10, y: CGFloat(size)/10)
        guard let output = filter.outputImage?.transformed(by: transform),
              let cg = context.createCGImage(output, from: output.extent) else {
            return UIImage()
        }
        return UIImage(cgImage: cg)
    }
}

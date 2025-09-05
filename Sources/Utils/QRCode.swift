import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let text: String
    let size: CGFloat

    var body: some View {
        Image(uiImage: UIImage.qr(from: text, size: size))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 6)
    }
}

extension UIImage {
    /// Tạo ảnh QR từ chuỗi với CoreImage (render vector), sau đó dùng ImageRenderer để đảm bảo kích thước/scale đẹp.
    static func qr(from text: String, size: CGFloat) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        let base = filter.outputImage ?? CIImage(color: .white)
        let scale = max(size / 128.0, 1.0)
        let transformed = base.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cg = context.createCGImage(transformed, from: transformed.extent) else {
            return UIImage()
        }
        let ciImage = UIImage(cgImage: cg)

        // iOS 16+: render bằng ImageRenderer để khử aliasing & set đúng scale
        let view = Image(uiImage: ciImage)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? ciImage
    }
}

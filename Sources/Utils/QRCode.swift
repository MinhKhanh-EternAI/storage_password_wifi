import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

/// Tạo UIImage từ text QR
enum QRCode {
    static func makeImage(from text: String, scale: CGFloat = 10) -> UIImage? {
        let data = Data(text.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

/// View hiển thị mã QR
struct QRCodeView: View {
    let text: String

    var body: some View {
        Group {
            if let img = QRCode.makeImage(from: text) {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ZStack {
                    Color(.secondarySystemBackground)
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .imageScale(.large)
                        Text("Không tạo được QR")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

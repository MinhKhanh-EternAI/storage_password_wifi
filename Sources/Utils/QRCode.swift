import CoreImage.CIFilterBuiltins
import UIKit

func qrImage(from string: String, scale: CGFloat = 12) -> UIImage {
    let data = Data(string.utf8)
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.setValue(data, forKey: "inputMessage")
    filter.correctionLevel = "M"

    let transform = CGAffineTransform(scaleX: scale, y: scale)
    guard let output = filter.outputImage?.transformed(by: transform),
          let cg = context.createCGImage(output, from: output.extent) else {
        return UIImage()
    }
    return UIImage(cgImage: cg)
}

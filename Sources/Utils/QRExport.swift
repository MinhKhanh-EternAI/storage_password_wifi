import UIKit

struct QRExport {
    let imageText: String

    init(imageText: String) {
        self.imageText = imageText
    }

    func makeImage() -> UIImage {
        qrImage(from: imageText, scale: 12)
    }

    func makePNGData() -> Data? {
        makeImage().pngData()
    }

    /// Ghi file PNG tạm và trả về URL để ShareLink dùng
    @discardableResult
    func makeTempFile(named filename: String = "wifi-qr.png") -> URL? {
        guard let data = makePNGData() else { return nil }
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("QRExport error:", error)
            return nil
        }
    }
}

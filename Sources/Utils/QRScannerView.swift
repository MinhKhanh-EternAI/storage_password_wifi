import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRScannerView
        init(_ parent: QRScannerView) { self.parent = parent }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  obj.type == .qr, let text = obj.stringValue else { return }
            parent.onFound(text)
        }
    }

    var onFound: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let session = AVCaptureSession()
        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return vc }

        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        vc.view.layer.addSublayer(preview)

        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

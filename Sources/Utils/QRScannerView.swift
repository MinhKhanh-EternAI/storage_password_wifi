import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerView
        init(_ parent: QRScannerView) { self.parent = parent }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard let m = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  m.type == .qr, let str = m.stringValue else { return }
            parent.onCode(str)
        }
    }

    var onCode: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return vc }
        let output = AVCaptureMetadataOutput()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = vc.view.layer.bounds
        vc.view.layer.addSublayer(preview)
        session.startRunning()
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

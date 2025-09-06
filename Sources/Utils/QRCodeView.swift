import SwiftUI

struct QRCodeView: View {
    let text: String

    var body: some View {
        Image(uiImage: qrImage(from: text, scale: 12))
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

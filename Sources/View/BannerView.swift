import SwiftUI

struct BannerView: View {
    let success: Bool
    let count: Int
    let message: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(success ? .green : .red)

            VStack(alignment: .leading, spacing: 4) {
                Text(success ? "THÀNH CÔNG!" : "THẤT BẠI!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(success ? .green : .red)

                if success {
                    Text(message ?? "")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text(message ?? "Có lỗi xảy ra")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

import SwiftUI

struct ProductImageView: View {
    let imageUrl: String?
    let size: CGFloat
    let placeholderIconSize: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
            .fill(imageUrl == nil ? DesignTokens.bgElevated : DesignTokens.bgSurface)
            .frame(width: size, height: size)
            .overlay {
                if let urlString = imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        placeholderIcon
                    }
                } else {
                    placeholderIcon
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
    }

    private var placeholderIcon: some View {
        Image(systemName: "pill.fill")
            .font(.system(size: placeholderIconSize))
            .foregroundStyle(DesignTokens.textTertiary)
    }
}

import SwiftUI

struct PillboxLid: View {
    let userName: String

    var body: some View {
        ZStack {
            // Personalized etching — centered on the full lid
            VStack(spacing: DesignTokens.spacing4) {
                // Decorative line
                Rectangle()
                    .fill(DesignTokens.textTertiary)
                    .frame(width: 40, height: 1)
                    .padding(.bottom, DesignTokens.spacing4)

                Text("\(userName)'s")
                    .font(Font.custom("GeistPixel-Grid", size: 28))
                    .foregroundStyle(DesignTokens.textSecondary)

                Text("Supplement Program")
                    .font(Font.custom("GeistPixel-Grid", size: 28))
                    .foregroundStyle(DesignTokens.textSecondary)

                // Decorative line
                Rectangle()
                    .fill(DesignTokens.textTertiary)
                    .frame(width: 40, height: 1)
                    .padding(.top, DesignTokens.spacing4)
            }
            .multilineTextAlignment(.center)

            // Slide hint pinned to top
            VStack(spacing: DesignTokens.spacing8) {
                Capsule()
                    .fill(DesignTokens.borderDefault)
                    .frame(width: 36, height: 4)

                Text("Slide to open")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textTertiary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, DesignTokens.spacing24)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .fill(DesignTokens.bgSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 2)
    }
}

import SwiftUI

struct DiscoveryCard: View {
    let tip: DiscoveryTip

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            // Category badge
            Text(tip.category.label)
                .font(DesignTokens.labelMono)
                .tracking(1.2)
                .foregroundStyle(tip.accentColor)
                .padding(.horizontal, DesignTokens.spacing8)
                .padding(.vertical, DesignTokens.spacing4)
                .background(tip.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))

            // Title
            Text(tip.title)
                .font(DesignTokens.bodyFont)
                .fontWeight(.semibold)
                .foregroundStyle(DesignTokens.textPrimary)

            // Body
            Text(tip.body)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(4)
        }
        .padding(DesignTokens.spacing16)
        .frame(width: 260, alignment: .leading)
        .frame(minHeight: 160, alignment: .top)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(tip.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DiscoveryCard(
        tip: DiscoveryTip(
            category: .didYouKnow,
            title: "Magnesium Glycinate",
            body: "Magnesium is involved in 300+ enzymatic reactions in your body.",
            accentColor: DesignTokens.accentSleep,
            supplementName: "Magnesium Glycinate"
        )
    )
    .padding()
    .background(DesignTokens.bgDeepest)
}

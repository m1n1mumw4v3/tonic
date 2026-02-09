import SwiftUI

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            // Header
            HStack {
                // Type badge
                Text(insight.type.label.uppercased())
                    .font(DesignTokens.labelMono)
                    .tracking(1.2)
                    .foregroundStyle(dimensionColor)
                    .padding(.horizontal, DesignTokens.spacing8)
                    .padding(.vertical, DesignTokens.spacing4)
                    .background(dimensionColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))

                Spacer()

                if !insight.isRead {
                    Circle()
                        .fill(DesignTokens.info)
                        .frame(width: 8, height: 8)
                }
            }

            // Title
            Text(insight.title)
                .font(DesignTokens.bodyFont)
                .fontWeight(.semibold)
                .foregroundStyle(DesignTokens.textPrimary)

            // Body preview
            Text(insight.body)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(3)

            // Disclaimer
            Text("Based on your self-reported data. Not medical advice.")
                .font(.custom("GeistMono-Regular", size: 9))
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(DesignTokens.spacing16)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(dimensionColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var dimensionColor: Color {
        if let dimension = insight.dimension {
            return dimension.color
        }
        return DesignTokens.info
    }
}

#Preview {
    InsightCard(
        insight: Insight(
            type: .correlation,
            title: "Magnesium is helping your sleep",
            body: "Over the past 3 weeks, your sleep scores have improved by 18% on days you took Magnesium Glycinate. This pattern is consistent across 21 data points.",
            dataPointsUsed: 21,
            dimension: .sleep
        )
    )
    .padding()
    .background(DesignTokens.bgDeepest)
}

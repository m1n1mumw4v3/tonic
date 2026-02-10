import SwiftUI

struct CompactInsightCard: View {
    let insight: CheckInInsight
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: DesignTokens.spacing12) {
            Image(systemName: insight.icon)
                .font(.system(size: 18))
                .foregroundStyle(insight.accentColor)

            Text(insight.message)
                .font(.custom("Geist-Regular", size: 14))
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .padding(DesignTokens.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(insight.accentColor.opacity(0.3), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    CompactInsightCard(
        insight: CheckInInsight(
            key: "streak_7",
            message: "7-day streak! Consistency is where the magic happens.",
            icon: "flame.fill",
            accentColor: DesignTokens.accentEnergy,
            dimension: nil
        )
    )
    .padding()
    .background(DesignTokens.bgDeepest)
}

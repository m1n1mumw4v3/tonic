import SwiftUI

struct MicroRewardCard: View {
    let content: MicroRewardContent

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var badge: (text: String, color: Color) {
        switch content {
        case .timeline:
            return ("TIMELINE", DesignTokens.accentClarity)
        case .adherence:
            return ("STREAK", DesignTokens.accentEnergy)
        case .tip:
            return ("TIP", DesignTokens.positive)
        }
    }

    private var bodyText: String {
        switch content {
        case .timeline(let milestone):
            return milestone.message
        case .adherence(let insight):
            return insight.message
        case .tip(let tip):
            return tip.message
        }
    }

    private var accentColor: Color {
        switch content {
        case .timeline(let milestone):
            return milestone.accentColor
        case .adherence(let insight):
            return insight.accentColor
        case .tip(let tip):
            return tip.accentColor
        }
    }

    private var icon: String {
        switch content {
        case .timeline:
            return "clock.arrow.circlepath"
        case .adherence:
            return "flame.fill"
        case .tip:
            return "lightbulb.fill"
        }
    }

    var body: some View {
        HStack(spacing: DesignTokens.spacing12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(accentColor)
                .frame(width: 32, height: 32)
                .background(accentColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                // Badge
                Text(badge.text)
                    .font(DesignTokens.labelMono)
                    .tracking(1.2)
                    .foregroundStyle(badge.color)

                // Body
                Text(bodyText)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .padding(DesignTokens.spacing16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .fill(DesignTokens.bgSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isVisible = true
                    }
                }
            }
        }
    }
}

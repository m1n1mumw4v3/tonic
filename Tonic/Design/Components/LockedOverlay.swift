import SwiftUI

struct LockedOverlay: ViewModifier {
    @Environment(AppState.self) private var appState
    var title: String = "Premium Feature"
    var subtitle: String = "Subscribe to unlock full access"

    func body(content: Content) -> some View {
        if appState.isSubscribed {
            content
        } else {
            content
                .blur(radius: 6)
                .allowsHitTesting(false)
                .overlay {
                    VStack(spacing: DesignTokens.spacing12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignTokens.textTertiary)

                        Text(title)
                            .font(DesignTokens.titleFont)
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text(subtitle)
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .multilineTextAlignment(.center)

                        CTAButton(title: "Unlock", style: .secondary) {
                            appState.showPaywall = true
                        }
                        .frame(width: 160)
                    }
                    .padding(DesignTokens.spacing24)
                }
        }
    }
}

extension View {
    func lockedOverlay(
        title: String = "Premium Feature",
        subtitle: String = "Subscribe to unlock full access"
    ) -> some View {
        modifier(LockedOverlay(title: title, subtitle: subtitle))
    }
}

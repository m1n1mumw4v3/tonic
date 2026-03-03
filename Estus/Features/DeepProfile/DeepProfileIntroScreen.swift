import SwiftUI

struct DeepProfileIntroScreen: View {
    let config: DeepProfileModuleConfig
    let onStart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, DesignTokens.spacing24)
            .padding(.top, DesignTokens.spacing24)

            Spacer()

            VStack(spacing: DesignTokens.spacing24) {
                // Icon
                Image(systemName: config.type.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(config.type.accentColor)

                // Title
                Text(config.type.displayName)
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .multilineTextAlignment(.center)

                // Description
                Text(config.introDescription)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.spacing16)

                // Meta info
                HStack(spacing: DesignTokens.spacing16) {
                    metaChip(icon: "list.bullet", text: "\(config.type.questionCount) questions")
                    metaChip(icon: "clock", text: config.type.estimatedTimeLabel)
                }

                // Disclaimer
                if let disclaimer = config.disclaimer {
                    Text(disclaimer)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.spacing24)
                }
            }
            .padding(.horizontal, DesignTokens.spacing24)

            Spacer()

            CTAButton(title: "Let's Go", style: .primary, action: onStart)
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
        }
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: DesignTokens.spacing4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.textTertiary)
            Text(text)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(.horizontal, DesignTokens.spacing12)
        .padding(.vertical, DesignTokens.spacing4)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
    }
}

import SwiftUI

struct CTAButton: View {
    let title: String
    let style: Style
    let action: () -> Void
    var spectrumBorder: Bool = false

    enum Style {
        case primary
        case secondary
        case ghost
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            Text(title)
                .font(DesignTokens.ctaFont)
                .tracking(0.32)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(background)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(border)
        }
        .buttonStyle(CTAPressStyle())
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            DesignTokens.textPrimary
        case .secondary:
            Color.clear
        case .ghost:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return DesignTokens.bgDeepest
        case .secondary:
            return DesignTokens.textPrimary
        case .ghost:
            return DesignTokens.textSecondary
        }
    }

    @ViewBuilder
    private var border: some View {
        if spectrumBorder {
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignTokens.accentSleep,
                            DesignTokens.accentEnergy,
                            DesignTokens.accentClarity,
                            DesignTokens.accentMood,
                            DesignTokens.accentGut
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        } else {
            switch style {
            case .primary, .ghost:
                EmptyView()
            case .secondary:
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.textPrimary, lineWidth: 1.5)
            }
        }
    }
}

private struct CTAPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        CTAButton(title: "Get Started", style: .primary) {}
        CTAButton(title: "Skip for now", style: .secondary) {}
        CTAButton(title: "Maybe later", style: .ghost) {}
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}

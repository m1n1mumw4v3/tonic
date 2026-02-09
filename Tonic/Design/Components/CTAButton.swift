import SwiftUI

struct CTAButton: View {
    let title: String
    let style: Style
    let action: () -> Void

    enum Style {
        case primary
        case secondary
    }

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
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            Color(hex: "#D6DEEB")
        case .secondary:
            Color.white.opacity(0.08)
                .background(.ultraThinMaterial)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color(hex: "#0E1025")
        case .secondary:
            return DesignTokens.textPrimary
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CTAButton(title: "Get Started", style: .primary) {}
        CTAButton(title: "Skip for now", style: .secondary) {}
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}

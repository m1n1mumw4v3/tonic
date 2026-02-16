import SwiftUI

struct PillboxCompartment: View {
    let supplement: PlanSupplement
    let isTaken: Bool
    let onToggle: () -> Void

    @State private var isPressed = false
    @State private var showCheckmark = false
    @State private var glowOpacity: CGFloat = 0

    private var iconConfig: SupplementIconConfig {
        SupplementIconRegistry.config(for: supplement.name)
    }

    private var shortName: String {
        SupplementIconRegistry.shortName(for: supplement.name)
    }

    private var accent: Color { iconConfig.accentColor }

    var body: some View {
        Button {
            onToggle()
        } label: {
            compartmentWell
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(duration: 0.3, bounce: 0.5), value: isPressed)
        .animation(.easeOut(duration: 0.25), value: isTaken)
        .onChange(of: isTaken) { _, newValue in
            if newValue {
                triggerTakenAnimation()
            } else {
                triggerUntakenAnimation()
            }
        }
    }

    // MARK: - Compartment Well

    private var compartmentWell: some View {
        VStack(spacing: DesignTokens.spacing2) {
            // Icon area (48pt)
            ZStack {
                iconCircle

                if showCheckmark {
                    Circle()
                        .fill(accent)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DesignTokens.bgDeepest)
                        )
                        .offset(x: 14, y: -16)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 48)

            // Label area (20pt)
            Text(shortName)
                .font(DesignTokens.captionFont)
                .foregroundStyle(isTaken ? accent : DesignTokens.textPrimary)
                .lineLimit(1)
                .frame(height: 20, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .modifier(WellMaterialModifier(
            isTaken: isTaken,
            accent: accent,
            glowOpacity: glowOpacity
        ))
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }

    // MARK: - Icon Circle

    private var iconCircle: some View {
        Circle()
            .fill(accent.opacity(0.15))
            .overlay(
                Circle()
                    .stroke(accent.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 44, height: 44)
            .overlay(iconContent)
    }

    @ViewBuilder
    private var iconContent: some View {
        switch iconConfig.iconType {
        case .pixelText(let text):
            Text(text)
                .font(pixelFont(for: text))
                .foregroundStyle(accent)
        case .sfSymbol(let name):
            if UIImage(systemName: name) != nil {
                Image(systemName: name)
                    .font(.system(size: 20))
                    .foregroundStyle(accent)
            } else {
                Image(systemName: "pill.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(accent)
            }
        }
    }

    private func pixelFont(for text: String) -> Font {
        switch text.count {
        case 1...2:
            return DesignTokens.pixelIconFont  // 18pt
        case 3:
            return DesignTokens.pixelIconSmall  // 14pt
        default:
            return Font.custom("GeistPixel-Grid", size: 11)
        }
    }

    // MARK: - Animations

    private func triggerTakenAnimation() {
        HapticManager.impact(.medium)

        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isPressed = false
        }

        withAnimation(.spring(duration: 0.35, bounce: 0.6)) {
            showCheckmark = true
        }

        withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 0.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                glowOpacity = 0
            }
        }
    }

    private func triggerUntakenAnimation() {
        HapticManager.impact(.light)

        withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
            showCheckmark = false
        }
    }

    func triggerCelebrationGlow() {
        withAnimation(.easeOut(duration: 0.4)) {
            glowOpacity = 0.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                glowOpacity = 0
            }
        }
    }
}

// MARK: - Well Material Modifier

private struct WellMaterialModifier: ViewModifier {
    let isTaken: Bool
    let accent: Color
    let glowOpacity: CGFloat

    func body(content: Content) -> some View {
        content
            .background(wellBackground)
            .overlay(chamferOverlay)
            .overlay(glowOverlay)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
    }

    private var wellBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .fill(DesignTokens.bgDeepest)
            if isTaken {
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .fill(accent.opacity(0.10))
            }
        }
    }

    private var chamferOverlay: some View {
        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
            .stroke(
                isTaken ? accent.opacity(0.30) : DesignTokens.borderDefault,
                lineWidth: 1
            )
    }

    private var glowOverlay: some View {
        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
            .fill(
                RadialGradient(
                    colors: [accent.opacity(glowOpacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 60
                )
            )
    }
}

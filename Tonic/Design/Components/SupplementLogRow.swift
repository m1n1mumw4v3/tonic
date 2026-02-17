import SwiftUI

struct SupplementLogRow: View {
    let supplement: PlanSupplement
    let isTaken: Bool
    let onToggle: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            HapticManager.impact(.light)
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                // Icon circle
                iconCircle
                    .frame(width: 28, height: 28)

                // Name + dosage
                VStack(alignment: .leading, spacing: 2) {
                    Text(shortName)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Text(supplement.dosage)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Toggle circle
                toggleCircle
                    .frame(width: 19, height: 19)
            }
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.vertical, DesignTokens.spacing12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                    .fill(Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(reduceMotion ? .none : .spring(duration: 0.2, bounce: 0.3), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    // MARK: - Icon Circle

    private var iconCircle: some View {
        Circle()
            .fill(accent.opacity(isTaken ? 0.22 : 0.12))
            .overlay(iconContent)
    }

    @ViewBuilder
    private var iconContent: some View {
        let foreground = accent
        Group {
            switch iconConfig.iconType {
            case .pixelText(let text):
                Text(text)
                    .font(pixelFont(for: text))
                    .foregroundStyle(foreground)
            case .sfSymbol(let name):
                if UIImage(systemName: name) != nil {
                    Image(systemName: name)
                        .font(.system(size: 12))
                        .foregroundStyle(foreground)
                } else {
                    Image(systemName: "pill.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(foreground)
                }
            }
        }
    }

    private func pixelFont(for text: String) -> Font {
        switch text.count {
        case 1...2:
            return Font.custom("GeistPixel-Grid", size: 12)
        default:
            return Font.custom("GeistPixel-Grid", size: 9)
        }
    }

    // MARK: - Toggle Circle

    private var toggleCircle: some View {
        ZStack {
            Circle()
                .stroke(isTaken ? DesignTokens.positive : DesignTokens.borderDefault, lineWidth: 1.5)
                .background(
                    Circle()
                        .fill(isTaken ? DesignTokens.positive : Color.clear)
                )

            if isTaken {
                AnimatedCheckmark(isChecked: true, color: .white, size: 10)
            }
        }
    }
}

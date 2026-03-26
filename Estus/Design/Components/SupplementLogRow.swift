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

    var body: some View {
        Button {
            onToggle()
            HapticManager.impact(.light)
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                SupplementIconView(
                    config: iconConfig,
                    size: DesignTokens.iconSizeSmall,
                    isTaken: isTaken
                )

                // Name + dosage
                VStack(alignment: .leading, spacing: 2) {
                    Text(shortName)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary.opacity(isTaken ? 0.4 : 1.0))
                        .strikethrough(isTaken, color: DesignTokens.textPrimary.opacity(0.4))
                        .lineLimit(1)

                    Text(supplement.dosage)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary.opacity(isTaken ? 0.5 : 1.0))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(shortName), \(supplement.dosage)")
        .accessibilityValue(isTaken ? "Taken" : "Not taken")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isTaken ? "Double tap to mark as not taken" : "Double tap to mark as taken")
    }

    // MARK: - Toggle Circle

    private var toggleCircle: some View {
        ZStack {
            Circle()
                .stroke(isTaken ? DesignTokens.textPrimary : DesignTokens.borderDefault, lineWidth: 1.5)
                .background(
                    Circle()
                        .fill(isTaken ? DesignTokens.textPrimary : Color.clear)
                )

            if isTaken {
                AnimatedCheckmark(isChecked: true, color: .white, size: 10)
            }
        }
    }
}

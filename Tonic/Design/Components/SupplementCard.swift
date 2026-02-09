import SwiftUI

struct SupplementCard: View {
    let name: String
    let dosage: String
    let timing: String
    let isTaken: Bool
    let onToggle: () -> Void

    @State private var showCheckmark = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                showCheckmark.toggle()
            }
            HapticManager.impact(.medium)
            onToggle()
        }) {
            HStack(spacing: DesignTokens.spacing12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                        .stroke(isTaken ? DesignTokens.positive : DesignTokens.borderDefault, lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if isTaken {
                        RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                            .fill(DesignTokens.positive)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DesignTokens.bgDeepest)
                            .scaleEffect(isTaken ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.3, bounce: 0.6), value: isTaken)
                    }
                }

                // Supplement info
                VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                    Text(name)
                        .font(DesignTokens.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(isTaken ? DesignTokens.textSecondary : DesignTokens.textPrimary)
                        .strikethrough(isTaken, color: DesignTokens.textTertiary)

                    Text(dosage)
                        .font(DesignTokens.dataMono)
                        .foregroundStyle(isTaken ? DesignTokens.textTertiary : DesignTokens.info)
                }

                Spacer()

                // Timing badge
                Text(timing.uppercased())
                    .font(DesignTokens.labelMono)
                    .tracking(1.2)
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.horizontal, DesignTokens.spacing8)
                    .padding(.vertical, DesignTokens.spacing4)
                    .background(DesignTokens.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
            }
            .padding(DesignTokens.spacing12)
            .background(isTaken ? DesignTokens.positive.opacity(0.05) : DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(isTaken ? DesignTokens.positive.opacity(0.2) : DesignTokens.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        SupplementCard(
            name: "Magnesium Glycinate",
            dosage: "400mg",
            timing: "evening",
            isTaken: false,
            onToggle: {}
        )
        SupplementCard(
            name: "Vitamin D3",
            dosage: "2000 IU",
            timing: "morning",
            isTaken: true,
            onToggle: {}
        )
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}

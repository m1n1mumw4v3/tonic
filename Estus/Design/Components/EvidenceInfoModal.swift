import SwiftUI

struct EvidenceInfoModal: View {
    let level: EvidenceLevel
    let onDismiss: () -> Void

    private var chipColor: Color {
        switch level {
        case .strong: DesignTokens.positive
        case .moderate: DesignTokens.info
        case .emerging: DesignTokens.accentEnergy
        }
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Modal card
            VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
                // Header
                HStack(spacing: DesignTokens.spacing8) {
                    Image(systemName: level.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(chipColor)

                    Text(level.displayText)
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DesignTokens.textTertiary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // Description
                Text(level.description)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.spacing24)
            .background(DesignTokens.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
            .padding(.horizontal, DesignTokens.spacing32)
        }
    }
}

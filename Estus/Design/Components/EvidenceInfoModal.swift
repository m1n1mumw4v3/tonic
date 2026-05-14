import SwiftUI

struct EvidenceInfoModal: View {
    let level: EvidenceLevel
    let onDismiss: () -> Void

    private let accent: Color = DesignTokens.accentMood

    private let overview: String =
        "Estus grades each supplement on a three-tier scale that weighs trial quality, sample size, replication across studies, and biological plausibility. The number of filled flasks reflects how robust the evidence base is — not how effective the supplement is for any individual."

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(alignment: .leading, spacing: DesignTokens.spacing20) {
                header
                Text(overview)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                    levelRow(.strong)
                    levelRow(.moderate)
                    levelRow(.emerging)
                }
            }
            .padding(DesignTokens.spacing24)
            .background(DesignTokens.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusCard)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
            .padding(.horizontal, DesignTokens.spacing24)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacing8) {
            Text("How we grade research")
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
            .accessibilityLabel("Close")
        }
    }

    // MARK: - Level Row

    private func levelRow(_ rowLevel: EvidenceLevel) -> some View {
        let isCurrent = rowLevel == level
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: DesignTokens.spacing8) {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < rowLevel.filledFlasks ? "flask.fill" : "flask")
                            .font(.system(size: 14))
                            .foregroundStyle(idx < rowLevel.filledFlasks ? accent : DesignTokens.textTertiary.opacity(0.45))
                    }
                }
                Text(rowLevel.displayText)
                    .font(.custom("Geist-Regular", size: 16))
                    .foregroundStyle(DesignTokens.textPrimary)
            }

            Text(rowLevel.description)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? accent.opacity(0.06) : DesignTokens.bgSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(isCurrent ? accent.opacity(0.4) : DesignTokens.borderDefault, lineWidth: isCurrent ? 1.5 : 1)
        )
    }
}

#Preview("Strong selected") {
    EvidenceInfoModal(level: .strong, onDismiss: {})
}

#Preview("Moderate selected") {
    EvidenceInfoModal(level: .moderate, onDismiss: {})
}

#Preview("Emerging selected") {
    EvidenceInfoModal(level: .emerging, onDismiss: {})
}

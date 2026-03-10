import SwiftUI

struct RecommendationCard: View {
    let supplement: Supplement
    let matchedGoals: [HealthGoal]
    let isSelected: Bool
    let isInPlan: Bool
    let isExcluded: Bool
    var exclusionReason: String = ""
    let onToggle: () -> Void

    var body: some View {
        Button {
            if !isInPlan && !isExcluded {
                HapticManager.selection()
                onToggle()
            }
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                // Icon
                SupplementIconView(
                    config: SupplementIconRegistry.config(for: supplement.name),
                    size: DesignTokens.iconSizeMedium,
                    useRoundedRect: true
                )

                // Info
                VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacing8) {
                        Text(supplement.name)
                            .font(DesignTokens.bodyFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text(supplement.commonDosageRange)
                            .font(DesignTokens.dataMono)
                            .foregroundStyle(DesignTokens.info)
                    }

                    if !matchedGoals.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(matchedGoals) { goal in
                                Text(goal.shortLabel)
                                    .font(.custom("GeistMono-Regular", size: 10))
                                    .tracking(0.5)
                                    .foregroundStyle(goal.accentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(goal.accentColor.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
                            }
                        }
                    }

                    if let notes = Optional(supplement.notes), !notes.isEmpty {
                        Text(notes)
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                // Action indicator
                if isExcluded {
                    VStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 18))
                            .foregroundStyle(DesignTokens.negative)
                        Text("Interaction")
                            .font(.custom("GeistMono-Regular", size: 8))
                            .foregroundStyle(DesignTokens.negative)
                    }
                } else if isInPlan {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignTokens.textTertiary)
                        Text("In plan")
                            .font(.custom("GeistMono-Regular", size: 8))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? DesignTokens.positive : DesignTokens.positive)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .padding(DesignTokens.spacing12)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(
                        isSelected ? DesignTokens.positive.opacity(0.3) : DesignTokens.borderDefault,
                        lineWidth: 1
                    )
            )
            .shadow(color: DesignTokens.cardShadowColor, radius: DesignTokens.cardShadowRadius, x: 0, y: DesignTokens.cardShadowY)
            .opacity(isExcluded ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isInPlan || isExcluded)
    }
}

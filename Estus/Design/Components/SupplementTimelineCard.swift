import SwiftUI

struct SupplementTimelineCard: View {
    let card: TimelineCardData
    let isExpanded: Bool
    var phaseBarProgress: CGFloat = 1
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent top border (inside the clip)
            card.accentColor
                .frame(height: 2)

            collapsedContent
                .padding(DesignTokens.spacing16)

            if isExpanded {
                expandedContent
            }

            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignTokens.textTertiary.opacity(0.3))
                .frame(width: 32, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.bottom, DesignTokens.spacing8)
        }
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .shadow(color: DesignTokens.cardShadowColor, radius: DesignTokens.cardShadowRadius, x: 0, y: DesignTokens.cardShadowY)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: - Collapsed Content

    private var collapsedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            // Row 1: Name + Phase badge
            HStack(alignment: .center) {
                Text(card.supplementName)
                    .font(.custom("Geist-SemiBold", size: 16))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("PHASE \(card.phaseState.currentPhase.phaseNumber) OF 4")
                    .font(DesignTokens.smallMono)
                    .tracking(0.5)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.horizontal, DesignTokens.spacing8)
                    .padding(.vertical, DesignTokens.spacing2)
                    .background(DesignTokens.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
            }

            // Row 2: Dosage + Timing
            Text("\(card.dosage) · \(card.timing.label)")
                .font(DesignTokens.labelMono)
                .foregroundStyle(DesignTokens.textSecondary)

            // Row 3: Phase progress bar
            PhaseProgressBar(
                currentPhase: card.phaseState.currentPhase,
                phaseProgress: card.phaseState.phaseProgress,
                accentColor: card.accentColor,
                animationProgress: phaseBarProgress
            )

            // Row 4: Day progress + goal chip
            HStack {
                dayProgressLabel
                Spacer()
                goalChip
            }
        }
    }

    private var dayProgressLabel: some View {
        Group {
            if card.phaseState.isComplete {
                Text("Steady state reached")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            } else {
                Text("Day \(card.phaseState.dayInPhase) of \(card.phaseState.totalDaysInPhase) in \(card.phaseState.currentPhase.label)")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
    }

    private var goalChip: some View {
        HStack(spacing: DesignTokens.spacing4) {
            Circle()
                .fill(card.primaryDimension.color)
                .frame(width: 6, height: 6)

            if let avg = card.currentAverage, let delta = card.deltaVsBaseline {
                // Data state: "Gut 6.3 ▲ 0.8"
                Text(card.primaryDimension.label.uppercased())
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textSecondary)

                Text(String(format: "%.1f", avg))
                    .font(.custom("GeistMono-Medium", size: 10))
                    .foregroundStyle(DesignTokens.textPrimary)

                if abs(delta) >= 0.1 {
                    HStack(spacing: 1) {
                        Image(systemName: delta >= 0 ? "triangle.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 5))
                        Text(String(format: "%.1f", abs(delta)))
                            .font(.custom("GeistMono-Medium", size: 10))
                    }
                    .foregroundStyle(delta > 0 ? DesignTokens.positive : DesignTokens.negative)
                }
            } else {
                // Baseline state: "Gut · Baseline 5.5"
                Text(card.primaryDimension.label.uppercased())
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textSecondary)

                Text("·")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textTertiary)

                Text("Baseline \(String(format: "%.1f", card.baselineScore))")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
        .padding(.horizontal, DesignTokens.spacing8)
        .padding(.vertical, DesignTokens.spacing4)
        .background(DesignTokens.bgElevated.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Rectangle()
                .fill(DesignTokens.borderSubtle)
                .frame(height: 1)

            Text(card.phaseContent.biologicalDescription)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            PhaseCalloutRow(
                icon: "eye",
                label: "WHAT TO WATCH FOR",
                text: card.phaseContent.watchFor,
                color: card.accentColor
            )

            PhaseCalloutRow(
                icon: "flag",
                label: "NEXT MILESTONE",
                text: card.phaseContent.nextMilestone,
                color: DesignTokens.info
            )
        }
        .padding(.horizontal, DesignTokens.spacing16)
        .padding(.bottom, DesignTokens.spacing8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Preview

#Preview {
    let sampleCard = TimelineCardData(
        id: UUID(),
        supplementName: "Magnesium Glycinate",
        dosage: "400mg",
        timing: .evening,
        tier: .core,
        primaryDimension: .sleep,
        accentColor: DesignTokens.accentSleep,
        phaseState: SupplementPhaseState.compute(
            daysOnPlan: 8,
            durations: SupplementPhaseDurations(loadingDays: 3, adaptationDays: 8, onsetDays: 14)
        ),
        phaseContent: SupplementKnowledgeBase.phaseContentFor(supplement: "Magnesium Glycinate", phase: .adaptation),
        baselineScore: 5.5,
        currentAverage: 6.3,
        deltaVsBaseline: 0.8
    )

    ScrollView {
        VStack(spacing: 16) {
            SupplementTimelineCard(card: sampleCard, isExpanded: false, onTap: {})
            SupplementTimelineCard(card: sampleCard, isExpanded: true, onTap: {})
        }
        .padding()
    }
    .background(DesignTokens.bgDeepest)
}

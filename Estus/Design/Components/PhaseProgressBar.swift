import SwiftUI

struct PhaseProgressBar: View {
    let currentPhase: SupplementPhase
    let phaseProgress: Double
    let accentColor: Color
    var animationProgress: CGFloat = 1

    private let barHeight: CGFloat = 4
    private let segmentSpacing: CGFloat = 2

    var body: some View {
        VStack(spacing: DesignTokens.spacing4) {
            phaseLabels
            segmentBar
        }
    }

    private var phaseLabels: some View {
        HStack(spacing: segmentSpacing) {
            ForEach(SupplementPhase.allCases, id: \.rawValue) { phase in
                Text(phase.shortLabel)
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(labelColor(for: phase))
                    .fontWeight(phase == currentPhase ? .bold : .regular)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var segmentBar: some View {
        HStack(spacing: segmentSpacing) {
            ForEach(SupplementPhase.allCases, id: \.rawValue) { phase in
                GeometryReader { geo in
                    let width = geo.size.width
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: barHeight / 2)
                            .fill(DesignTokens.bgElevated)

                        // Fill
                        RoundedRectangle(cornerRadius: barHeight / 2)
                            .fill(accentColor)
                            .frame(width: fillWidth(for: phase, totalWidth: width))
                    }
                }
                .frame(height: barHeight)
            }
        }
    }

    private func labelColor(for phase: SupplementPhase) -> Color {
        if phase == currentPhase {
            return accentColor
        } else if phase < currentPhase {
            return DesignTokens.textPrimary
        } else {
            return DesignTokens.textTertiary
        }
    }

    private func fillWidth(for phase: SupplementPhase, totalWidth: CGFloat) -> CGFloat {
        if phase < currentPhase {
            return totalWidth * animationProgress
        } else if phase == currentPhase {
            return totalWidth * CGFloat(phaseProgress) * animationProgress
        } else {
            return 0
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        PhaseProgressBar(
            currentPhase: .loading,
            phaseProgress: 0.5,
            accentColor: DesignTokens.accentSleep
        )

        PhaseProgressBar(
            currentPhase: .adaptation,
            phaseProgress: 0.7,
            accentColor: DesignTokens.accentClarity
        )

        PhaseProgressBar(
            currentPhase: .onset,
            phaseProgress: 0.3,
            accentColor: DesignTokens.accentMood
        )

        PhaseProgressBar(
            currentPhase: .steadyState,
            phaseProgress: 1.0,
            accentColor: DesignTokens.positive
        )
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}

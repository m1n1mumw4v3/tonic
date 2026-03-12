import SwiftUI

struct WellbeingScoreRing: View {
    let sleepScore: Int
    let energyScore: Int
    let clarityScore: Int
    let moodScore: Int
    let gutScore: Int
    var size: CGFloat = 180
    var lineWidth: CGFloat = 12
    var centerLabel: String = "OVERALL"
    var overallVariance: Double? = nil
    var varianceLabel: String? = nil
    var animated: Bool = true

    @State private var animationProgress: CGFloat = 0

    private var wellbeingScore: Double {
        WellbeingScore.calculate(
            sleep: sleepScore, energy: energyScore,
            clarity: clarityScore, mood: moodScore, gut: gutScore
        )
    }

    private var dimensions: [(WellnessDimension, Int)] {
        [
            (.sleep, sleepScore),
            (.energy, energyScore),
            (.clarity, clarityScore),
            (.mood, moodScore),
            (.gut, gutScore)
        ]
    }

    private var totalScore: Double {
        Double(sleepScore + energyScore + clarityScore + moodScore + gutScore)
    }

    private var lastNonZeroSegmentIndex: Int? {
        dimensions.lastIndex(where: { $0.1 > 0 })
    }

    var body: some View {
        VStack(spacing: DesignTokens.spacing24) {
            // Ring
            ZStack {
                // Background ring with recessed inner shadow
                Circle()
                    .stroke(DesignTokens.bgElevated, lineWidth: lineWidth)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: lineWidth)
                            .frame(width: size, height: size)
                            .blur(radius: 3)
                            .mask(
                                Circle()
                                    .stroke(Color.white, lineWidth: lineWidth)
                                    .frame(width: size, height: size)
                            )
                    )

                // Segment glow layers (behind the ring)
                ForEach(Array(dimensions.enumerated()), id: \.0) { index, item in
                    let (dimension, _) = item
                    let startAngle = segmentStartAngle(for: index)
                    let endAngle = segmentEndAngle(for: index)

                    Circle()
                        .trim(from: startAngle, to: startAngle + (endAngle - startAngle) * animationProgress)
                        .stroke(
                            dimension.color.opacity(0.35),
                            style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .butt)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 8)
                }

                // Dimension segments (butt caps for flush joins)
                ForEach(Array(dimensions.enumerated()), id: \.0) { index, item in
                    let (dimension, _) = item
                    let startAngle = segmentStartAngle(for: index)
                    let endAngle = segmentEndAngle(for: index)

                    Circle()
                        .trim(from: startAngle, to: startAngle + (endAngle - startAngle) * animationProgress)
                        .stroke(
                            dimension.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                }

                // Round terminations at start and end of the full ring
                if totalScore > 0 {
                    // Round cap at ring start (first segment start)
                    Circle()
                        .trim(from: segmentStartAngle(for: 0), to: segmentStartAngle(for: 0) + 0.001)
                        .stroke(
                            dimensions[0].0.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                        .opacity(animationProgress > 0 ? 1 : 0)

                    // Round cap at ring end (last non-zero segment end)
                    if let lastIndex = lastNonZeroSegmentIndex {
                        let endAngle = segmentEndAngle(for: lastIndex)
                        let animatedEnd = segmentStartAngle(for: lastIndex) + (endAngle - segmentStartAngle(for: lastIndex)) * animationProgress

                        Circle()
                            .trim(from: max(0, animatedEnd - 0.001), to: animatedEnd)
                            .stroke(
                                dimensions[lastIndex].0.color,
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                            )
                            .frame(width: size, height: size)
                            .rotationEffect(.degrees(-90))
                    }
                }

                // Center score
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", wellbeingScore))
                        .font(.custom("Geist-Medium", size: size * 0.25))
                        .foregroundStyle(DesignTokens.textPrimary)

                    if centerLabel != "OVERALL", !centerLabel.isEmpty {
                        // Non-default label (e.g. "BASELINE")
                        Text(centerLabel)
                            .font(DesignTokens.smallMono)
                            .tracking(1.2)
                            .foregroundStyle(DesignTokens.textSecondary)
                    } else if let variance = overallVariance, let label = varianceLabel {
                        // Variance indicator
                        VStack(spacing: 1) {
                            Text(varianceText(variance))
                                .font(.custom("GeistMono-Medium", size: size * 0.067))
                                .foregroundStyle(varianceColor(variance))
                            Text(label.uppercased())
                                .font(.custom("GeistMono-Regular", size: size * 0.061))
                                .tracking(0.8)
                                .foregroundStyle(DesignTokens.textTertiary)
                        }
                    }
                }
            }

            // Dimension scores — full-width columns
            HStack(spacing: DesignTokens.spacing8) {
                ForEach(dimensions, id: \.0) { dimension, score in
                    VStack(spacing: 3) {
                        Text("\(score)")
                            .font(.custom("GeistMono-Medium", size: 18))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text(dimension.label.uppercased())
                            .font(.custom("GeistMono-Regular", size: 10))
                            .tracking(0.6)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.spacing8)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                            .stroke(dimension.color, lineWidth: 1)
                    )
                }
            }
        }
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }

    /// Maximum possible total across all 5 dimensions (each scored 0–10).
    private let maxPossibleScore: CGFloat = 50.0

    private func segmentStartAngle(for index: Int) -> CGFloat {
        guard totalScore > 0 else { return 0 }
        var start: CGFloat = 0
        for i in 0..<index {
            start += CGFloat(dimensions[i].1) / maxPossibleScore
        }
        return start
    }

    private func segmentEndAngle(for index: Int) -> CGFloat {
        guard totalScore > 0 else { return 0 }
        let segmentSize = CGFloat(dimensions[index].1) / maxPossibleScore
        return segmentStartAngle(for: index) + segmentSize
    }

    private func varianceColor(_ value: Double) -> Color {
        if abs(value) < 0.15 {
            return DesignTokens.textTertiary
        }
        return value > 0 ? DesignTokens.positive : DesignTokens.negative
    }

    private func varianceText(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))"
    }
}

#Preview {
    WellbeingScoreRing(
        sleepScore: 7,
        energyScore: 6,
        clarityScore: 8,
        moodScore: 7,
        gutScore: 7
    )
    .padding()
    .background(DesignTokens.bgDeepest)
}

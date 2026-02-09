import SwiftUI

struct WellbeingScoreRing: View {
    let sleepScore: Int
    let energyScore: Int
    let clarityScore: Int
    let moodScore: Int
    let gutScore: Int
    var size: CGFloat = 140
    var lineWidth: CGFloat = 10
    var animated: Bool = true

    @State private var animationProgress: CGFloat = 0

    private var wellbeingScore: Int {
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

    var body: some View {
        VStack(spacing: DesignTokens.spacing12) {
            // Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(DesignTokens.bgElevated, lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // Dimension segments
                ForEach(Array(dimensions.enumerated()), id: \.0) { index, item in
                    let (dimension, score) = item
                    let startAngle = segmentStartAngle(for: index)
                    let endAngle = segmentEndAngle(for: index)

                    Circle()
                        .trim(from: startAngle, to: startAngle + (endAngle - startAngle) * animationProgress)
                        .stroke(
                            dimension.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                }

                // Center score
                VStack(spacing: 2) {
                    Text("\(wellbeingScore)")
                        .font(.custom("GeistMono-Medium", size: size * 0.25))
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("WELLBEING")
                        .font(DesignTokens.smallMono)
                        .tracking(1.2)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }

            // Mini dimension scores
            HStack(spacing: DesignTokens.spacing12) {
                ForEach(dimensions, id: \.0) { dimension, score in
                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(DesignTokens.dataMono)
                            .foregroundStyle(dimension.color)
                        Text(dimension.shortLabel)
                            .font(.custom("GeistMono-Regular", size: 8))
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
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

    private func segmentStartAngle(for index: Int) -> CGFloat {
        guard totalScore > 0 else { return 0 }
        let gap: CGFloat = 0.01
        var start: CGFloat = 0
        for i in 0..<index {
            start += CGFloat(dimensions[i].1) / CGFloat(totalScore) + gap
        }
        return start
    }

    private func segmentEndAngle(for index: Int) -> CGFloat {
        guard totalScore > 0 else { return 0 }
        let gap: CGFloat = 0.01
        let segmentSize = CGFloat(dimensions[index].1) / CGFloat(totalScore)
        return segmentStartAngle(for: index) + max(0, segmentSize - gap)
    }
}

#Preview {
    WellbeingScoreRing(
        sleepScore: 72,
        energyScore: 65,
        clarityScore: 80,
        moodScore: 70,
        gutScore: 68
    )
    .padding()
    .background(DesignTokens.bgDeepest)
}

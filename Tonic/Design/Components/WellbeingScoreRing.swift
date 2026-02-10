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
        VStack(spacing: DesignTokens.spacing12) {
            // Ring
            ZStack {
                // Background ring with recessed inner shadow
                Circle()
                    .stroke(DesignTokens.bgElevated, lineWidth: lineWidth)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.3), lineWidth: lineWidth)
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

                    Text("OVERALL")
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
        var start: CGFloat = 0
        for i in 0..<index {
            start += CGFloat(dimensions[i].1) / CGFloat(totalScore)
        }
        return start
    }

    private func segmentEndAngle(for index: Int) -> CGFloat {
        guard totalScore > 0 else { return 0 }
        let segmentSize = CGFloat(dimensions[index].1) / CGFloat(totalScore)
        return segmentStartAngle(for: index) + segmentSize
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

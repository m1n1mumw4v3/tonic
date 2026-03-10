import SwiftUI

struct GhostTrendsTeaser: View {
    let checkInCount: Int
    let checkInsNeeded: Int = 3

    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var remaining: Int { max(0, checkInsNeeded - checkInCount) }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
            Text("WELLBEING TREND")
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            // Ghost bar chart
            ghostBarChart

            // Ghost dimension rows
            ghostDimensionRows

            // Divider
            Rectangle()
                .fill(DesignTokens.borderDefault)
                .frame(height: 1)

            // Unlock callout
            unlockCallout
        }
        .cardStyle()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }

    // MARK: - Ghost Bar Chart

    private var ghostBarChart: some View {
        let ghostHeights: [CGFloat] = [0.35, 0.55, 0.45, 0.65, 0.50, 0.40, 0.60]
        let barAreaHeight: CGFloat = 64

        return HStack(alignment: .bottom, spacing: DesignTokens.spacing8) {
            ForEach(Array(ghostHeights.enumerated()), id: \.offset) { _, height in
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.bgElevated)
                    .frame(height: barAreaHeight * height)
                    .frame(maxWidth: .infinity)
            }
        }
        .overlay {
            // Shimmer sweep
            if !reduceMotion {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let bandWidth = width * 0.4
                    let offset = -bandWidth + (width + bandWidth * 2) * shimmerPhase

                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: bandWidth)
                    .offset(x: offset)
                    .allowsHitTesting(false)
                }
                .clipped()
            }
        }
    }

    // MARK: - Ghost Dimension Rows

    private var ghostDimensionRows: some View {
        VStack(spacing: DesignTokens.spacing8) {
            ForEach(WellnessDimension.allCases) { dimension in
                HStack(spacing: DesignTokens.spacing12) {
                    Image(systemName: dimension.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(dimension.color.opacity(0.3))
                        .frame(width: 20)

                    Text(dimension.label)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                        .frame(width: 52, alignment: .leading)

                    // Empty progress bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.bgElevated)
                        .frame(height: 6)

                    Text("—.—")
                        .font(DesignTokens.dataMono)
                        .foregroundStyle(DesignTokens.textTertiary.opacity(0.5))
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Unlock Callout

    private var unlockCallout: some View {
        HStack(spacing: DesignTokens.spacing12) {
            // Progress dots
            HStack(spacing: DesignTokens.spacing4) {
                ForEach(0..<checkInsNeeded, id: \.self) { index in
                    Circle()
                        .fill(index < checkInCount ? DesignTokens.positive : DesignTokens.bgElevated)
                        .frame(width: 8, height: 8)
                        .overlay {
                            if index >= checkInCount {
                                Circle()
                                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
                            }
                        }
                }
            }

            Text(calloutText)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)

            Spacer()
        }
    }

    private var calloutText: AttributedString {
        let count = remaining
        let word = count == 1 ? "check-in" : "check-ins"
        var result = AttributedString("\(count) more \(word) to unlock your first trend")
        if let range = result.range(of: "\(count)") {
            result[range].font = DesignTokens.ctaFont
        }
        return result
    }
}

#Preview("0 check-ins") {
    ScrollView {
        GhostTrendsTeaser(checkInCount: 0)
            .padding()
    }
    .background(DesignTokens.bgDeepest)
}

#Preview("2 check-ins") {
    ScrollView {
        GhostTrendsTeaser(checkInCount: 2)
            .padding()
    }
    .background(DesignTokens.bgDeepest)
}

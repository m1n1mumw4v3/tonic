import SwiftUI

struct OnsetTimelineCard: View {
    let entries: [OnsetTimelineEntry]
    let daysOnPlan: Int
    var barGrowProgress: CGFloat = 1
    var showMarker: Bool = true

    private let maxAxisDays = 84
    private let axisPoints: [(day: Int, label: String)] = [
        (0, "NOW"), (7, "1W"), (14, "2W"), (28, "4W"), (56, "8W"), (84, "12W")
    ]
    private let nameColumnWidth: CGFloat = 100
    private let barHeight: CGFloat = 6
    private let checkmarkSize: CGFloat = 20
    private let rowHeight: CGFloat = 52
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    @State private var barAreaWidth: CGFloat = 0

    private var leftColumnWidth: CGFloat {
        nameColumnWidth + DesignTokens.spacing8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
            headerRow

            if entries.isEmpty {
                Text("No onset data available")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textTertiary)
            } else {
                timelineContent
            }

            Text("Timelines reflect clinical research averages. Individual results vary based on baseline, consistency, and biology.")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("WHEN TO EXPECT RESULTS")
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            Spacer()

            if daysOnPlan > 0 {
                Text("DAY \(daysOnPlan)")
                    .font(DesignTokens.labelMono)
                    .tracking(0.8)
                    .foregroundStyle(DesignTokens.info)
            }
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            axisLabels
                .padding(.bottom, DesignTokens.spacing4)

            ForEach(entries) { entry in
                supplementRow(entry)
            }
        }
        .overlay {
            if showMarker, daysOnPlan > 0, barAreaWidth > 0 {
                nowLine
            }
        }
    }

    // MARK: - Axis Labels

    private var axisLabels: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: leftColumnWidth, height: 1)

            GeometryReader { geo in
                let width = geo.size.width

                ZStack {
                    ForEach(Array(axisPoints.enumerated()), id: \.offset) { index, point in
                        let fraction = CGFloat(index) / CGFloat(axisPoints.count - 1)

                        Text(point.label)
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(DesignTokens.textTertiary)
                            .fixedSize()
                            .position(x: fraction * width, y: 7)
                    }
                }
                .onAppear { barAreaWidth = width }
                .onChange(of: geo.size.width) { _, w in barAreaWidth = w }
            }
            .frame(height: 14)
        }
    }

    // MARK: - Now Line

    private var nowLine: some View {
        GeometryReader { geo in
            let fraction = xFraction(for: min(daysOnPlan, maxAxisDays))
            let xPos = leftColumnWidth + fraction * barAreaWidth

            // Dot at top
            Circle()
                .fill(DesignTokens.info)
                .frame(width: 6, height: 6)
                .position(x: xPos, y: 11)

            // Vertical line
            Path { path in
                path.move(to: CGPoint(x: xPos, y: 16))
                path.addLine(to: CGPoint(x: xPos, y: geo.size.height))
            }
            .stroke(DesignTokens.borderDefault, lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Supplement Row

    private func supplementRow(_ entry: OnsetTimelineEntry) -> some View {
        HStack(alignment: .center, spacing: DesignTokens.spacing8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.supplementName)
                    .font(.custom("Geist-SemiBold", size: 14))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)

                Text("\(formatDuration(entry.minDays)) \u{2014} \(formatDuration(entry.maxDays))")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .frame(width: nameColumnWidth, alignment: .leading)

            // Bar area
            let inRange = daysOnPlan >= entry.minDays && daysOnPlan <= entry.maxDays
            GeometryReader { geo in
                let width = geo.size.width
                let centerY = geo.size.height / 2
                let startFraction = xFraction(for: entry.minDays)
                let endFraction = xFraction(for: min(entry.maxDays, maxAxisDays))
                let barStart = startFraction * width
                let barEnd = endFraction * width
                let rawBarWidth = barEnd - barStart
                let animatedWidth = max(barHeight, rawBarWidth * barGrowProgress)

                // Track
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(DesignTokens.bgElevated)
                    .frame(width: width, height: barHeight)
                    .position(x: width / 2, y: centerY)

                // Onset bar
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(barColor)
                    .frame(width: animatedWidth, height: barHeight)
                    .mask(alignment: .leading) {
                        if entry.maxDays > maxAxisDays {
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: max(0, animatedWidth - 16))
                                LinearGradient(
                                    colors: [.white, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 16)
                            }
                        } else {
                            Rectangle()
                        }
                    }
                    .position(x: barStart + animatedWidth / 2, y: centerY)

                // Progress markers
                if showMarker, daysOnPlan > 0, barGrowProgress >= 1 {
                    if daysOnPlan >= entry.maxDays {
                        // Completed checkmark at end of bar
                        completedCheckmark
                            .position(x: barEnd, y: centerY)
                    } else if daysOnPlan >= entry.minDays {
                        // In-progress dot at current position
                        let nowX = xFraction(for: daysOnPlan) * width
                        Circle()
                            .fill(DesignTokens.bgSurface)
                            .frame(width: 8, height: 8)
                            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 0.5)
                            .position(x: nowX, y: centerY)
                    }
                }
            }
            .opacity(inRange ? 1.0 : 0.4)
        }
        .frame(height: rowHeight)
    }

    // MARK: - Checkmark

    private var completedCheckmark: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.positive)
                .frame(width: checkmarkSize, height: checkmarkSize)
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Helpers

    /// Non-linear position mapping: axis ticks are evenly spaced visually
    private func xFraction(for day: Int) -> CGFloat {
        let ticks = axisPoints.map(\.day)
        let clamped = min(day, maxAxisDays)

        for i in 0..<(ticks.count - 1) {
            if clamped <= ticks[i + 1] {
                let segStart = CGFloat(ticks[i])
                let segEnd = CGFloat(ticks[i + 1])
                let local = (CGFloat(clamped) - segStart) / (segEnd - segStart)
                let segWidth = 1.0 / CGFloat(ticks.count - 1)
                return CGFloat(i) * segWidth + local * segWidth
            }
        }
        return 1.0
    }

    private var barColor: Color { DesignTokens.accentGut }

    private func formatDuration(_ days: Int) -> String {
        if days < 7 { return "\(days)d" }
        if days <= 28 && days % 7 == 0 { return "\(days / 7)w" }
        if days < 28 { return "\(days)d" }
        let months = max(1, Int(round(Double(days) / 30.0)))
        return "\(months)mo"
    }
}

// MARK: - Previews

#Preview("Early State") {
    let entries: [OnsetTimelineEntry] = [
        OnsetTimelineEntry(supplementName: "L-Theanine", tier: .core, minDays: 1, maxDays: 7, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Magnesium Glycinate", tier: .core, minDays: 7, maxDays: 14, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Omega-3 (EPA/DHA)", tier: .core, minDays: 30, maxDays: 60, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Melatonin", tier: .supporting, minDays: 1, maxDays: 3, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Vitamin B Complex", tier: .targeted, minDays: 7, maxDays: 21, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Probiotics", tier: .targeted, minDays: 14, maxDays: 30, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Berberine", tier: .supporting, minDays: 30, maxDays: 90, onsetDescription: ""),
    ]

    return ScrollView {
        OnsetTimelineCard(entries: entries, daysOnPlan: 1)
            .padding()
    }
    .background(DesignTokens.bgDeepest)
}

#Preview("Day 41") {
    let entries: [OnsetTimelineEntry] = [
        OnsetTimelineEntry(supplementName: "L-Theanine", tier: .core, minDays: 1, maxDays: 7, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Magnesium Glycinate", tier: .core, minDays: 7, maxDays: 14, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Omega-3 (EPA/DHA)", tier: .core, minDays: 30, maxDays: 60, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Melatonin", tier: .supporting, minDays: 1, maxDays: 3, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Vitamin B Complex", tier: .targeted, minDays: 7, maxDays: 21, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Probiotics", tier: .targeted, minDays: 14, maxDays: 30, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Berberine", tier: .supporting, minDays: 30, maxDays: 90, onsetDescription: ""),
    ]

    return ScrollView {
        OnsetTimelineCard(entries: entries, daysOnPlan: 41)
            .padding()
    }
    .background(DesignTokens.bgDeepest)
}

#Preview("With Long Onset") {
    let entries: [OnsetTimelineEntry] = [
        OnsetTimelineEntry(supplementName: "Ashwagandha KSM-66", tier: .core, minDays: 3, maxDays: 28, onsetDescription: ""),
        OnsetTimelineEntry(supplementName: "Iron", tier: .targeted, minDays: 14, maxDays: 180, onsetDescription: ""),
    ]

    return ScrollView {
        OnsetTimelineCard(entries: entries, daysOnPlan: 30)
            .padding()
    }
    .background(DesignTokens.bgDeepest)
}

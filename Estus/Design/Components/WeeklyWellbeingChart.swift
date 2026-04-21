import SwiftUI

// MARK: - Weekly Day Data Model

struct WeeklyDayData: Identifiable {
    let id = UUID()
    let date: Date
    let dayLabel: String
    let isToday: Bool
    let scores: [WellnessDimension: Int]?

    var hasData: Bool { scores != nil }

    var totalScore: Int {
        guard let scores else { return 0 }
        return scores.values.reduce(0, +)
    }

    var wellbeingAverage: Double {
        guard let scores else { return 0 }
        return Double(scores.values.reduce(0, +)) / Double(scores.count)
    }
}

// MARK: - Weekly Wellbeing Chart

struct WeeklyWellbeingChart: View {
    let weeklyData: [WeeklyDayData]
    var selectedIndex: Int?
    var onSelectDay: ((Int) -> Void)?

    @State private var animationProgress: CGFloat = 0
    @State private var selectedDimension: WellnessDimension?
    @State private var ridgelineReveal: CGFloat = 0

    private let maxTotal: CGFloat = 50 // 5 dimensions × 10 max each
    private let barAreaHeight: CGFloat = 160

    private var barWidth: CGFloat {
        weeklyData.count <= 7 ? 28 : 7
    }

    private var barSpacing: CGFloat {
        weeklyData.count <= 7 ? DesignTokens.spacing8 : 2
    }

    var body: some View {
        VStack(spacing: DesignTokens.spacing16) {
            if let selectedDimension {
                ridgelineChart(for: selectedDimension)
            } else {
                barChart
            }
            legendRow
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
                animationProgress = 1
            }
        }
        .onChange(of: weeklyData.count) { _, _ in
            animationProgress = 0
            withAnimation(.easeOut(duration: 0.9)) {
                animationProgress = 1
            }
            if selectedDimension != nil {
                ridgelineReveal = 0
                withAnimation(.easeOut(duration: 0.7)) {
                    ridgelineReveal = 1
                }
            }
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: DesignTokens.spacing4) {
            ForEach(WellnessDimension.allCases) { dim in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDimension = selectedDimension == dim ? nil : dim
                    }
                } label: {
                    let isSelected = selectedDimension == dim
                    Text(dim.label)
                        .font(.custom("Geist-Regular", size: 11))
                        .foregroundStyle(isSelected ? .white : dim.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(isSelected ? dim.color : Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(dim.color, lineWidth: 1)
                        )
                        .opacity(selectedDimension == nil || isSelected ? 1 : 0.4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        let isCompact = weeklyData.count > 7

        return HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(Array(weeklyData.enumerated()), id: \.element.id) { index, day in
                let showLabel = !isCompact
                    || index == 0
                    || index == weeklyData.count - 1
                    || index % 7 == 0
                    || selectedIndex == index

                VStack(spacing: isCompact ? 2 : DesignTokens.spacing4) {
                    barColumn(for: day, at: index)
                        .frame(height: barAreaHeight)

                    dayLabel(for: day, at: index, visible: showLabel, isCompact: isCompact)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectDay?(index)
                }
            }
        }
    }

    @ViewBuilder
    private func dayLabel(for day: WeeklyDayData, at index: Int, visible: Bool, isCompact: Bool) -> some View {
        if visible {
            Text(day.dayLabel)
                .font(.custom("Geist-Regular", size: isCompact ? 10 : 11))
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(
                    day.isToday ? DesignTokens.textPrimary :
                    selectedIndex == index ? DesignTokens.textPrimary :
                    DesignTokens.textTertiary
                )
        } else {
            Color.clear.frame(height: isCompact ? 12 : 14)
        }
    }

    // MARK: - Ridgeline Chart

    private func ridgelineChart(for dim: WellnessDimension) -> some View {
        let isCompact = weeklyData.count > 7

        return HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(Array(weeklyData.enumerated()), id: \.element.id) { index, day in
                let showLabel = !isCompact
                    || index == 0
                    || index == weeklyData.count - 1
                    || index % 7 == 0
                    || selectedIndex == index

                VStack(spacing: isCompact ? 2 : DesignTokens.spacing4) {
                    Color.clear
                        .frame(height: barAreaHeight)

                    dayLabel(for: day, at: index, visible: showLabel, isCompact: isCompact)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectDay?(index)
                }
            }
        }
        .overlay(alignment: .top) {
            ridgelineOverlay(for: dim)
                .frame(height: barAreaHeight)
                .allowsHitTesting(false)
        }
        .task(id: dim) {
            ridgelineReveal = 0
            withAnimation(.easeOut(duration: 0.7)) {
                ridgelineReveal = 1
            }
        }
    }

    private func ridgelineOverlay(for dim: WellnessDimension) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let count = max(CGFloat(weeklyData.count), 1)
            let stepWidth = width / count

            let points: [CGPoint] = weeklyData.enumerated().map { index, day in
                let x = (CGFloat(index) + 0.5) * stepWidth
                let score = CGFloat(day.scores?[dim] ?? 0)
                let clampedScore = min(max(score, 0), 10)
                let y = barAreaHeight - (clampedScore / 10.0) * barAreaHeight * animationProgress
                return CGPoint(x: x, y: y)
            }

            ZStack {
                // Baseline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: barAreaHeight))
                    path.addLine(to: CGPoint(x: width, y: barAreaHeight))
                }
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)

                // Area fill
                smoothPath(points: points, closed: true)
                    .fill(
                        LinearGradient(
                            colors: [dim.color.opacity(0.35), dim.color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(Double(ridgelineReveal))

                // Line
                smoothPath(points: points, closed: false)
                    .trim(from: 0, to: ridgelineReveal)
                    .stroke(dim.color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Points (staggered along the line)
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    if weeklyData[index].hasData {
                        let pointProgress = CGFloat(index) / max(CGFloat(points.count - 1), 1)
                        let visible = ridgelineReveal >= pointProgress
                        Circle()
                            .fill(dim.color)
                            .frame(width: 5, height: 5)
                            .position(point)
                            .scaleEffect(visible ? 1 : 0)
                            .opacity(visible ? 1 : 0)
                            .animation(.easeOut(duration: 0.25), value: visible)
                    }
                }
            }
        }
    }

    private func smoothPath(points: [CGPoint], closed: Bool) -> Path {
        Path { path in
            guard let first = points.first else { return }

            if closed {
                path.move(to: CGPoint(x: first.x, y: barAreaHeight))
                path.addLine(to: first)
            } else {
                path.move(to: first)
            }

            for i in 1..<points.count {
                let prev = points[i - 1]
                let cur = points[i]
                let midX = (prev.x + cur.x) / 2
                path.addCurve(
                    to: cur,
                    control1: CGPoint(x: midX, y: prev.y),
                    control2: CGPoint(x: midX, y: cur.y)
                )
            }

            if closed, let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: barAreaHeight))
                path.closeSubpath()
            }
        }
    }

    // MARK: - Single Bar Column

    @ViewBuilder
    private func barColumn(for day: WeeklyDayData, at index: Int) -> some View {
        let isSelected = selectedIndex == index
        let columnProgress = staggeredProgress(for: index)

        if day.hasData, let scores = day.scores {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                let dimensions: [WellnessDimension] = [.gut, .mood, .clarity, .energy, .sleep]
                let total = CGFloat(day.totalScore)
                let scaledHeight = (total / maxTotal) * barAreaHeight * columnProgress

                VStack(spacing: 0) {
                    ForEach(Array(dimensions.enumerated()), id: \.offset) { segIndex, dim in
                        let score = CGFloat(scores[dim] ?? 0)
                        let segmentHeight = total > 0 ? (score / total) * scaledHeight : 0

                        dim.color
                            .frame(height: segmentHeight)
                    }
                }
                .frame(width: barWidth)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 6,
                    bottomLeadingRadius: 2,
                    bottomTrailingRadius: 2,
                    topTrailingRadius: 6
                ))
            }
        } else {
            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.bgElevated)
                    .frame(width: barWidth, height: 8 * columnProgress)
            }
        }
    }

    private func staggeredProgress(for index: Int) -> CGFloat {
        let count = max(CGFloat(weeklyData.count), 1)
        let staggerWindow: CGFloat = 0.6
        let perBarOffset = staggerWindow / count
        let start = perBarOffset * CGFloat(index)
        let duration = max(1 - staggerWindow, 0.01)
        return max(0, min(1, (animationProgress - start) / duration))
    }
}

// MARK: - Daily Overview Card

struct DailyOverviewCard: View {
    let dayData: WeeklyDayData
    let varianceText: String?

    @State private var pillAnimation: CGFloat = 0

    private let pillWidth: CGFloat = 12
    private let pillMaxHeight: CGFloat = 48

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing16) {
            leftSide
            Spacer()
            rightSide
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                pillAnimation = 1
            }
        }
        .onChange(of: dayData.id) { _, _ in
            pillAnimation = 0
            withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                pillAnimation = 1
            }
        }
    }

    // MARK: - Left Side

    private var leftSide: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
            Text(dayData.isToday ? "TODAY" : dayData.date.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            if dayData.hasData {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", dayData.wellbeingAverage))
                        .font(DesignTokens.displayFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("/ 10")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                if let variance = varianceText {
                    Text(variance)
                        .font(DesignTokens.smallMono)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            } else {
                Text("No check-in")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textTertiary)
            }
        }
    }

    // MARK: - Right Side (Mini Pill Bars)

    private var rightSide: some View {
        HStack(spacing: 6) {
            ForEach(WellnessDimension.allCases) { dim in
                let score = dayData.scores?[dim] ?? 0
                let fillHeight = CGFloat(score) / 10.0 * pillMaxHeight * pillAnimation

                VStack(spacing: 4) {
                    ZStack(alignment: .bottom) {
                        // Background track
                        RoundedRectangle(cornerRadius: pillWidth / 2)
                            .fill(DesignTokens.bgElevated)
                            .frame(width: pillWidth, height: pillMaxHeight)

                        // Colored fill
                        RoundedRectangle(cornerRadius: pillWidth / 2)
                            .fill(dim.color)
                            .frame(width: pillWidth, height: max(fillHeight, dayData.hasData ? 2 : 0))
                    }

                    Text("\(score)")
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(dayData.hasData ? dim.color : DesignTokens.textTertiary)
                }
            }
        }
    }
}

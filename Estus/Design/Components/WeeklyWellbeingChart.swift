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

    private let maxTotal: CGFloat = 50 // 5 dimensions × 10 max each
    private let barAreaHeight: CGFloat = 160
    private let barWidth: CGFloat = 28

    var body: some View {
        VStack(spacing: DesignTokens.spacing16) {
            barChart
            legendRow
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                animationProgress = 1
            }
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: DesignTokens.spacing12) {
            ForEach(WellnessDimension.allCases) { dim in
                HStack(spacing: 4) {
                    Circle()
                        .fill(dim.color)
                        .frame(width: 6, height: 6)
                    Text(dim.label)
                        .font(DesignTokens.smallMono)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
        }
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.spacing8) {
            ForEach(Array(weeklyData.enumerated()), id: \.element.id) { index, day in
                VStack(spacing: DesignTokens.spacing4) {
                    barColumn(for: day, at: index)
                        .frame(height: barAreaHeight)

                    Text(day.dayLabel)
                        .font(.custom("GeistMono-Regular", size: 10))
                        .foregroundStyle(
                            day.isToday ? DesignTokens.textPrimary :
                            selectedIndex == index ? DesignTokens.textPrimary :
                            DesignTokens.textTertiary
                        )
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectDay?(index)
                }
            }
        }
    }

    // MARK: - Single Bar Column

    @ViewBuilder
    private func barColumn(for day: WeeklyDayData, at index: Int) -> some View {
        let isSelected = selectedIndex == index

        if day.hasData, let scores = day.scores {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                let dimensions: [WellnessDimension] = [.gut, .mood, .clarity, .energy, .sleep]
                let total = CGFloat(day.totalScore)
                let scaledHeight = (total / maxTotal) * barAreaHeight * animationProgress

                VStack(spacing: 0) {
                    ForEach(Array(dimensions.enumerated()), id: \.offset) { segIndex, dim in
                        let score = CGFloat(scores[dim] ?? 0)
                        let segmentHeight = total > 0 ? (score / total) * scaledHeight : 0

                        let opacity: Double = day.isToday || isSelected ? 0.85 : 0.35

                        dim.color.opacity(opacity)
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
                    .frame(width: barWidth, height: 8 * animationProgress)
            }
        }
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
            Text(dayData.isToday ? "TODAY" : dayData.dayLabel)
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

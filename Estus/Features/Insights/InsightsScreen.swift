import SwiftUI
import UIKit

struct InsightsScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = InsightsViewModel()
    @State private var selectedPeriod: InsightsPeriod = .week

    // MARK: - Animation State

    @State private var showHeader = false
    @State private var showTimelineHeader = false
    @State private var showSummaryCard = false
    @State private var expandedCardId: UUID? = nil
    @State private var cardAppearStates: [UUID: Bool] = [:]
    @State private var phaseBarProgress: CGFloat = 0
    @State private var showGhostTrends = false
    @State private var showTrendCard = false
    @State private var showDimensions = false
    @State private var showStats = false
    @State private var barAnimationProgress: CGFloat = 0
    @State private var dimensionBarProgress: CGFloat = 0
    @State private var highlightedBarIndex: Int?

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
                    // Header
                    insightsHeader
                        .opacity(showHeader ? 1 : 0)
                        .offset(y: showHeader || reduceMotion ? 0 : 12)

                    if !viewModel.hasActivePlan {
                        noPlanState
                    } else {
                        // Timeline header
                        timelineHeader
                            .opacity(showTimelineHeader ? 1 : 0)
                            .offset(y: showTimelineHeader || reduceMotion ? 0 : 12)

                        // Summary card
                        if let summary = viewModel.timelineSummary {
                            TimelineSummaryCard(summary: summary)
                                .opacity(showSummaryCard ? 1 : 0)
                                .offset(y: showSummaryCard || reduceMotion ? 0 : 12)
                        }

                        // Per-supplement cards
                        ForEach(viewModel.timelineCards) { card in
                            SupplementTimelineCard(
                                card: card,
                                isExpanded: expandedCardId == card.id,
                                phaseBarProgress: phaseBarProgress,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        expandedCardId = expandedCardId == card.id ? nil : card.id
                                    }
                                }
                            )
                            .opacity(cardAppearStates[card.id] == true ? 1 : 0)
                            .offset(y: cardAppearStates[card.id] == true || reduceMotion ? 0 : 12)
                        }

                        if viewModel.isEarlyState {
                            // Ghost trends teaser
                            GhostTrendsTeaser(checkInCount: viewModel.checkInCount)
                                .opacity(showGhostTrends ? 1 : 0)
                                .offset(y: showGhostTrends || reduceMotion ? 0 : 12)
                        } else {
                            // Real trend data
                            if !viewModel.periodData.isEmpty {
                                VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
                                    weeklyTrendCard
                                        .opacity(showTrendCard ? 1 : 0)
                                        .offset(y: showTrendCard || reduceMotion ? 0 : 12)

                                    Rectangle()
                                        .fill(DesignTokens.borderDefault)
                                        .frame(height: 1)
                                        .opacity(showDimensions ? 1 : 0)

                                    dimensionBreakdown
                                        .opacity(showDimensions ? 1 : 0)
                                        .offset(y: showDimensions || reduceMotion ? 0 : 12)

                                    Rectangle()
                                        .fill(DesignTokens.borderDefault)
                                        .frame(height: 1)
                                        .opacity(showStats ? 1 : 0)

                                    statsRow
                                        .opacity(showStats ? 1 : 0)
                                        .offset(y: showStats || reduceMotion ? 0 : 12)
                                }
                                .lockedOverlay(
                                    title: "Insights",
                                    subtitle: "Subscribe to unlock wellness trends"
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.screenMargin)
                .padding(.bottom, DesignTokens.spacing32)
            }
        }
        .onAppear {
            viewModel.loadTimeline(appState: appState)
            viewModel.load(appState: appState, period: selectedPeriod)
            startEntranceAnimation()
        }
        .onChange(of: selectedPeriod) {
            highlightedBarIndex = nil
            viewModel.load(appState: appState, period: selectedPeriod)
        }
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        let fadeDuration: Double = reduceMotion ? 0.15 : 0.4

        let headerDelay: Double = reduceMotion ? 0.02 : 0.10
        let timelineHeaderDelay: Double = reduceMotion ? 0.04 : 0.20
        let summaryDelay: Double = reduceMotion ? 0.06 : 0.35
        let cardBaseDelay: Double = reduceMotion ? 0.08 : 0.50
        let cardStagger: Double = reduceMotion ? 0.02 : 0.08

        // Phase 1: Screen header
        DispatchQueue.main.asyncAfter(deadline: .now() + headerDelay) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showHeader = true
            }
        }

        // Phase 2: Timeline header
        DispatchQueue.main.asyncAfter(deadline: .now() + timelineHeaderDelay) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showTimelineHeader = true
            }
        }

        // Phase 3: Summary card
        DispatchQueue.main.asyncAfter(deadline: .now() + summaryDelay) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showSummaryCard = true
            }
        }

        // Phase 4: Staggered card reveals
        for (index, card) in viewModel.timelineCards.enumerated() {
            let delay = cardBaseDelay + cardStagger * Double(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    cardAppearStates[card.id] = true
                }
            }
        }

        // Phase 5: Phase bars fill (after last card + 0.1s)
        let phaseBarDelay = cardBaseDelay + cardStagger * Double(viewModel.timelineCards.count) + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.10 : phaseBarDelay)) {
            withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.6)) {
                phaseBarProgress = 1
            }
        }

        if viewModel.isEarlyState {
            // Ghost trends
            let ghostDelay = phaseBarDelay + 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.10 : ghostDelay)) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    showGhostTrends = true
                }
            }
        } else {
            // Real data (existing stagger)
            let dataBaseDelay = phaseBarDelay + 0.15
            let trendDelay: Double = reduceMotion ? 0.06 : dataBaseDelay
            let barGrowDelay: Double = reduceMotion ? 0.08 : dataBaseDelay + 0.15
            let dimDelay: Double = reduceMotion ? 0.08 : dataBaseDelay + 0.10
            let dimBarGrowDelay: Double = reduceMotion ? 0.10 : dataBaseDelay + 0.30
            let statsDelay: Double = reduceMotion ? 0.10 : dataBaseDelay + 0.25

            DispatchQueue.main.asyncAfter(deadline: .now() + trendDelay) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    showTrendCard = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + barGrowDelay) {
                withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.5)) {
                    barAnimationProgress = 1
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + dimDelay) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    showDimensions = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + dimBarGrowDelay) {
                withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.5)) {
                    dimensionBarProgress = 1
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + statsDelay) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    showStats = true
                }
            }
        }
    }

    // MARK: - Header

    private var insightsHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            HStack(alignment: .bottom) {
                Text("Insights")
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)

                Spacer()

                if !viewModel.isEarlyState {
                    periodPicker
                }
            }

            Rectangle()
                .fill(DesignTokens.borderDefault)
                .frame(height: 1)
                .padding(.top, DesignTokens.spacing4)
        }
        .padding(.top, DesignTokens.spacing8)
    }

    // MARK: - Timeline Header

    private var timelineHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing2) {
            Text("Your Timeline")
                .font(DesignTokens.titleFont)
                .foregroundStyle(DesignTokens.textPrimary)
            Text("Where each supplement is in its biological journey")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(InsightsPeriod.allCases) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(DesignTokens.labelMono)
                        .tracking(0.8)
                        .foregroundStyle(
                            selectedPeriod == period
                                ? DesignTokens.textPrimary
                                : DesignTokens.textTertiary
                        )
                        .padding(.horizontal, DesignTokens.spacing12)
                        .padding(.vertical, DesignTokens.spacing4)
                        .background(
                            selectedPeriod == period
                                ? DesignTokens.bgElevated
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                }
            }
        }
        .padding(2)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - No Plan State

    private var noPlanState: some View {
        VStack(spacing: DesignTokens.spacing16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.textTertiary)
            Text("Create your plan to see your timeline")
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignTokens.spacing48)
    }

    // MARK: - Weekly Trend Card

    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
            trendCardHeader

            // Bar chart with baseline overlay
            barChartSection

            // Trend indicator
            if let trend = viewModel.trendDirection {
                HStack(spacing: DesignTokens.spacing4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(trend.color)
                    Text(trend.label)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    private var trendCardHeader: some View {
        HStack {
            Text("WELLBEING SCORE")
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            Spacer()

            if let avg = viewModel.periodAverage {
                Text(String(format: "%.1f", avg))
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(DesignTokens.info)
                Text("AVG")
                    .font(DesignTokens.labelMono)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
    }

    @State private var chartWidth: CGFloat = 0

    private var barChartSection: some View {
        let barAreaHeight: CGFloat = 100
        let isMonthly = selectedPeriod == .month
        let barSpacing: CGFloat = isMonthly ? 2 : DesignTokens.spacing8

        return VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(Array(viewModel.periodData.enumerated()), id: \.element.id) { index, day in
                    VStack(spacing: isMonthly ? 2 : DesignTokens.spacing4) {
                        if !isMonthly {
                            Text(String(format: "%.1f", day.score))
                                .font(DesignTokens.labelMono)
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        barView(
                            for: day,
                            barAreaHeight: barAreaHeight,
                            isHighlighted: isMonthly && highlightedBarIndex == index
                        )

                        if !isMonthly {
                            Text(day.dayLabel)
                                .font(.custom("GeistMono-Regular", size: 9))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(isMonthly && highlightedBarIndex != nil && highlightedBarIndex != index ? 0.3 : 1.0)
                }
            }

            // Scrub tooltip (monthly only)
            if isMonthly, let index = highlightedBarIndex, index < viewModel.periodData.count {
                let day = viewModel.periodData[index]
                let barCount = CGFloat(viewModel.periodData.count)
                let stepWidth = chartWidth / barCount
                let xPos = stepWidth * CGFloat(index) + stepWidth / 2
                let clampedX = max(28, min(chartWidth - 28, xPos))

                ZStack {
                    VStack(spacing: 1) {
                        Text(day.fullDateLabel)
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(DesignTokens.textSecondary)
                        Text(String(format: "%.1f", day.score))
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(DesignTokens.info)
                    }
                    .fixedSize()
                    .position(x: clampedX, y: 14)
                }
                .frame(height: 28)
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear { chartWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { _, newWidth in chartWidth = newWidth }
            }
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard isMonthly else { return }
                    let barCount = viewModel.periodData.count
                    guard barCount > 0 else { return }
                    let stepWidth = chartWidth / CGFloat(barCount)
                    let index = Int(value.location.x / stepWidth)
                    let clamped = max(0, min(barCount - 1, index))
                    if clamped != highlightedBarIndex {
                        withAnimation(.easeOut(duration: 0.1)) {
                            highlightedBarIndex = clamped
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        highlightedBarIndex = nil
                    }
                }
        )
    }

    private func barView(for day: DayData, barAreaHeight: CGFloat, isHighlighted: Bool = false) -> some View {
        let fullHeight = max(8, CGFloat(day.score / 10.0) * barAreaHeight)
        let barHeight = fullHeight * barAnimationProgress
        let cornerRadius: CGFloat = selectedPeriod == .month ? 2 : 4

        return RoundedRectangle(cornerRadius: cornerRadius)
            .fill(isHighlighted ? DesignTokens.info : DesignTokens.textPrimary)
            .frame(height: barHeight)
    }

    @ViewBuilder
    private func baselineOverlay(barAreaHeight: CGFloat) -> some View {
        if let baseline = viewModel.baselineScore, baseline > 0 {
            let yOffset = CGFloat(baseline / 10.0) * barAreaHeight
            // Position from bottom of bar area; account for day label height (~14pt)
            HStack(spacing: 0) {
                BaselineLine()
                    .stroke(
                        DesignTokens.textSecondary,
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                    .frame(height: 1)

                Text("BASELINE")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.leading, 4)
            }
            .offset(y: -yOffset + (barAreaHeight / 2) - 7)
            .opacity(Double(barAnimationProgress))
        }
    }

    // MARK: - Dimension Breakdown

    private var dimensionBreakdown: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            HStack(spacing: DesignTokens.spacing12) {
                Text("DIMENSIONS")
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)

                Spacer()

                Text("AVG")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 32, alignment: .center)

                Text("VS\nPRIOR")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 36, alignment: .center)
            }

            ForEach(viewModel.dimensionAverages) { dim in
                dimensionRow(dim)
            }
        }
        .cardStyle()
    }

    private func dimensionRow(_ dim: DimensionAverage) -> some View {
        HStack(spacing: DesignTokens.spacing12) {
            Image(systemName: dim.dimension.icon)
                .font(.system(size: 14))
                .foregroundStyle(dim.dimension.color)
                .frame(width: 20)

            Text(dim.dimension.label)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .frame(width: 52, alignment: .leading)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.bgElevated)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(dim.dimension.color.opacity(0.8))
                        .frame(width: geometry.size.width * CGFloat(dim.average / 10.0) * dimensionBarProgress)
                }
            }
            .frame(height: 6)

            Text(String(format: "%.1f", dim.average))
                .font(DesignTokens.dataMono)
                .foregroundStyle(dim.dimension.color)
                .frame(width: 32, alignment: .trailing)

            // Change indicator
            if let change = dim.change {
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text(String(format: "%.1f", abs(change)))
                        .font(DesignTokens.smallMono)
                }
                .foregroundStyle(change >= 0 ? DesignTokens.positive : DesignTokens.negative)
                .frame(width: 36, alignment: .center)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: DesignTokens.spacing12) {
            statCard(
                value: "\(viewModel.currentStreak)",
                label: "DAY STREAK",
                icon: "flame.fill",
                color: DesignTokens.accentEnergy
            )

            statCard(
                value: viewModel.adherencePercentage,
                label: "ADHERENCE",
                icon: "pill.fill",
                color: DesignTokens.positive
            )

            statCard(
                value: "\(viewModel.totalCheckIns)",
                label: "CHECK-INS",
                icon: "checkmark.circle.fill",
                color: DesignTokens.info
            )
        }
    }

    private func statCard(
        value: String,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: DesignTokens.spacing8) {
            // Icon with radial glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(DesignTokens.dataMono)
                .foregroundStyle(DesignTokens.textPrimary)

            Text(label)
                .font(.custom("GeistMono-Regular", size: 8))
                .tracking(0.8)
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.spacing12)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .overlay(alignment: .top) {
            // Accent top border
            UnevenRoundedRectangle(
                topLeadingRadius: DesignTokens.radiusMedium,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: DesignTokens.radiusMedium
            )
            .fill(color)
            .frame(height: 2)
        }
        .shadow(color: DesignTokens.cardShadowColor, radius: DesignTokens.cardShadowRadius, x: 0, y: DesignTokens.cardShadowY)
    }
}

// MARK: - Baseline Line Shape

private struct BaselineLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview("Data State") {
    let appState = AppState()
    appState.loadDemoData()

    return InsightsScreen()
        .environment(appState)
}

#Preview("Early State") {
    let appState = AppState()

    return InsightsScreen()
        .environment(appState)
}

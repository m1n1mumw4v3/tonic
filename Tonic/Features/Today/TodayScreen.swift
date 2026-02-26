import SwiftUI

struct TodayScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = TodayViewModel()
    @State private var phaseCheckTimer: Timer?
    @State private var checkInCollapsed = false
    @State private var checkInExpanded = false
    @State private var insightPage: UUID?

    private var phase: TodayViewModel.TodayPhase {
        viewModel.currentPhase(appState: appState)
    }

    private var currentInsightIndex: Int {
        guard let insightPage else { return 0 }
        return viewModel.insightFeed.firstIndex(where: { $0.id == insightPage }) ?? 0
    }

    var body: some View {
        @Bindable var state = appState

        ZStack(alignment: .bottom) {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacing24) {
                    // 1. Header
                    headerSection

                    // 2. Wellbeing Score Card
                    wellbeingScoreCard

                    // 3. Yesterday Section (if applicable)
                    if viewModel.showYesterdaySection {
                        yesterdaySection
                    }

                    // 4. Supplements + Check-In
                    supplementAndCheckInSection

                    // 6. Micro-reward card
                    if viewModel.allTaken, let content = viewModel.microRewardContent {
                        MicroRewardCard(content: content)
                    }

                    // 7. Deep Profile Card
                    DeepProfileHomeCard()

                    // 8. Feed Section
                    feedSection
                }
                .padding(.horizontal, DesignTokens.screenMargin)
                .padding(.bottom, DesignTokens.spacing32)
            }
        }
        .sheet(isPresented: $state.showSettings) {
            SettingsScreen()
                .environment(appState)
        }
        .sheet(isPresented: $state.showPaywall) {
            PaywallScreen(
                viewModel: Self.paywallViewModel(from: appState),
                onSubscribe: {
                    appState.isSubscribed = true
                    appState.showPaywall = false
                },
                onDismiss: {
                    appState.showPaywall = false
                }
            )
        }
        .onAppear {
            viewModel.load(appState: appState)
            startPhaseTimer()
            if viewModel.wellbeingSubmitted {
                checkInCollapsed = true
            }
        }
        .onDisappear {
            phaseCheckTimer?.invalidate()
        }
        .onChange(of: viewModel.wellbeingSubmitted) { _, submitted in
            if submitted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        checkInCollapsed = true
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.4)) {
                    checkInCollapsed = false
                    checkInExpanded = false
                }
            }
        }
        .onChange(of: viewModel.allTaken) { _, allTaken in
            if allTaken && !viewModel.hasPlayedCompletionAnimation {
                viewModel.hasPlayedCompletionAnimation = true
                HapticManager.notification(.success)
                viewModel.generateMicroReward(appState: appState)
            }
            if allTaken {
                viewModel.updateStreakIfDayComplete(appState: appState)
            }
        }
    }

    // MARK: - Phase Timer

    private func startPhaseTimer() {
        phaseCheckTimer?.invalidate()
        phaseCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            // Force view refresh by touching greeting
            viewModel.greeting = "\(Date().greetingPrefix), \(appState.userName)"
            viewModel.dateLabel = Date().monoDateLabel
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
            HStack {
                Text(viewModel.greeting)
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)

                Spacer()

                streakBadge

                Button {
                    appState.showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }

            Text(viewModel.dateLabel.uppercased())
                .font(DesignTokens.labelMono)
                .tracking(1.2)
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(.top, DesignTokens.spacing8)
    }

    // MARK: - Streak Badge

    private var streakBadge: some View {
        let dayComplete = appState.isDayComplete
        let streak = appState.streak.currentStreak
        let color = DesignTokens.accentEnergy

        return HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
            Text("\(streak)")
                .font(DesignTokens.dataMono)
                .foregroundStyle(color)
        }
        .padding(.horizontal, DesignTokens.spacing8)
        .padding(.vertical, DesignTokens.spacing4)
        .background(color.opacity(dayComplete ? 0.25 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
        .emberGlow(isActive: dayComplete)
        .shadow(color: dayComplete ? color.opacity(0.4) : .clear, radius: 6, x: 0, y: 0)
        .animation(.easeInOut(duration: 0.4), value: dayComplete)
    }

    // MARK: - Wellbeing Score Card

    @ViewBuilder
    private var wellbeingScoreCard: some View {
        if let scoreCheckIn = appState.mostRecentWellbeingScore {
            VStack(spacing: DesignTokens.spacing16) {
                WellbeingScoreRing(
                    sleepScore: scoreCheckIn.sleepScore,
                    energyScore: scoreCheckIn.energyScore,
                    clarityScore: scoreCheckIn.clarityScore,
                    moodScore: scoreCheckIn.moodScore,
                    gutScore: scoreCheckIn.gutScore
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.spacing12)
        } else {
            VStack(spacing: DesignTokens.spacing16) {
                WellbeingScoreRing(
                    sleepScore: 0,
                    energyScore: 0,
                    clarityScore: 0,
                    moodScore: 0,
                    gutScore: 0,
                    animated: false
                )
                .opacity(0.3)

                Text("Complete your daily check-in to see your score")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.spacing12)
        }
    }

    // MARK: - Yesterday Section

    private var yesterdaySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textTertiary)

                Text("YESTERDAY \u{2014} \(viewModel.yesterdayRemainingCount) remaining")
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)

                Spacer()
            }

            if let plan = appState.activePlan {
                let active = plan.supplements.filter { !$0.isRemoved }
                    .sorted { $0.timing.sortOrder < $1.timing.sortOrder }

                SupplementLogList(
                    supplements: active,
                    supplementStates: viewModel.yesterdaySupplementStates,
                    onToggle: { id in viewModel.toggleYesterdaySupplement(id, appState: appState) }
                )
            }
        }
    }

    // MARK: - Supplement Section

    @ViewBuilder
    private var supplementAndCheckInSection: some View {
        if let plan = appState.activePlan {
            let visible = viewModel.visibleSupplements(for: phase, plan: plan)

            VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                if !visible.isEmpty {
                    SupplementLogList(
                        supplements: visible,
                        supplementStates: viewModel.supplementStates,
                        onToggle: { id in viewModel.toggleSupplement(id, appState: appState) },
                        onTakeAllSection: { ids in viewModel.takeAllByIDs(ids, appState: appState) },
                        amProgress: viewModel.amProgress,
                        pmProgress: viewModel.pmProgress,
                        amComplete: viewModel.amComplete,
                        pmComplete: viewModel.pmComplete
                    )
                }

                // Check-In title (only when open)
                if !checkInCollapsed {
                    Text("How are you feeling today?")
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, DesignTokens.spacing8)
                        .transition(.opacity)
                }

                wellbeingCheckInSection
                    .padding(.top, checkInCollapsed ? DesignTokens.spacing8 : 0)
            }
        }
    }

    // MARK: - Wellbeing Check-In Section

    private var wellbeingCheckInSection: some View {
        let showSliders = !checkInCollapsed || checkInExpanded

        return VStack(spacing: 0) {
            // Collapsed header (visible once submitted)
            if checkInCollapsed {
                HStack(spacing: DesignTokens.spacing4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(DesignTokens.accentHeart)
                    Text("CHECK-IN")
                        .font(.custom("Geist-SemiBold", size: 16))
                        .tracking(1.5)
                        .foregroundStyle(DesignTokens.textSecondary)
                    HStack(spacing: 4) {
                        AnimatedCheckmark(isChecked: true, color: .white, size: 8)
                        Text("COMPLETE")
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, DesignTokens.spacing8)
                    .padding(.vertical, 3)
                    .background(DesignTokens.positive)
                    .clipShape(Capsule())
                    .transition(.opacity)
                    Spacer()
                    HStack(spacing: DesignTokens.spacing4) {
                        Text(checkInExpanded ? "Edit" : "")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textTertiary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DesignTokens.textTertiary)
                            .rotationEffect(.degrees(checkInExpanded ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            checkInExpanded.toggle()
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.screenMargin)
                .padding(.top, DesignTokens.spacing12)
                .padding(.bottom, showSliders ? DesignTokens.spacing4 : DesignTokens.spacing12)
                .transition(.opacity)
            }

            // Open state: spectrum bar (only when not collapsed)
            if !checkInCollapsed {
                SpectrumBar(height: 2)
            }

            // Sliders + CTA
            if showSliders {
                VStack(spacing: DesignTokens.spacing16) {
                    VStack(spacing: DesignTokens.spacing20) {
                        WellnessSlider(
                            dimension: .sleep,
                            value: $viewModel.sleepScore,
                            lowLabel: WellnessDimension.sleep.lowLabel,
                            highLabel: WellnessDimension.sleep.highLabel,
                            averageValue: viewModel.trailingAverages[.sleep]
                        )
                        WellnessSlider(
                            dimension: .energy,
                            value: $viewModel.energyScore,
                            lowLabel: WellnessDimension.energy.lowLabel,
                            highLabel: WellnessDimension.energy.highLabel,
                            averageValue: viewModel.trailingAverages[.energy]
                        )
                        WellnessSlider(
                            dimension: .clarity,
                            value: $viewModel.clarityScore,
                            lowLabel: WellnessDimension.clarity.lowLabel,
                            highLabel: WellnessDimension.clarity.highLabel,
                            averageValue: viewModel.trailingAverages[.clarity]
                        )
                        WellnessSlider(
                            dimension: .mood,
                            value: $viewModel.moodScore,
                            lowLabel: WellnessDimension.mood.lowLabel,
                            highLabel: WellnessDimension.mood.highLabel,
                            averageValue: viewModel.trailingAverages[.mood]
                        )
                        WellnessSlider(
                            dimension: .gut,
                            value: $viewModel.gutScore,
                            lowLabel: WellnessDimension.gut.lowLabel,
                            highLabel: WellnessDimension.gut.highLabel,
                            averageValue: viewModel.trailingAverages[.gut]
                        )
                    }

                    CTAButton(title: "Save Check-In", style: .primary) {
                        viewModel.submitWellbeingCheckIn(appState: appState)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            checkInExpanded = false
                        }
                    }
                }
                .padding(DesignTokens.spacing16)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: checkInCollapsed)
        .animation(.easeInOut(duration: 0.5), value: checkInExpanded)
        .background(
            ZStack {
                if checkInCollapsed {
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(
                            AngularGradient(
                                colors: DesignTokens.spectrumColors + [DesignTokens.spectrumColors[0]],
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .blur(radius: 8)
                        .opacity(0.4)
                        .transition(.opacity)
                }

                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .fill(DesignTokens.bgSurface)
            }
            .animation(.easeInOut(duration: 0.6), value: checkInCollapsed)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .overlay(
            SpectrumProgressBorder(
                progress: checkInCollapsed ? 1.0 : 0,
                cornerRadius: DesignTokens.radiusMedium
            )
            .animation(.easeOut(duration: 0.5), value: checkInCollapsed)
        )
        .shadow(color: .black.opacity(checkInCollapsed ? 0 : 0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Feed Section

    @ViewBuilder
    private var feedSection: some View {
        if !viewModel.insightFeed.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                HStack {
                    Text("RECENT INSIGHTS")
                        .font(DesignTokens.sectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(DesignTokens.textSecondary)

                    Spacer()

                    if viewModel.insightFeed.count > 1 {
                        Text("\(currentInsightIndex + 1)/\(viewModel.insightFeed.count)")
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: DesignTokens.spacing12) {
                        ForEach(viewModel.insightFeed) { insight in
                            InsightCard(insight: insight, onDismiss: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.dismissInsight(insight.id)
                                    // Advance to next card, or stay on last
                                    if let first = viewModel.insightFeed.first {
                                        insightPage = first.id
                                    }
                                }
                            })
                            .containerRelativeFrame(.horizontal)
                            .onAppear {
                                viewModel.markInsightRead(insight.id)
                            }
                            .id(insight.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $insightPage)
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .onAppear {
                    if insightPage == nil {
                        insightPage = viewModel.insightFeed.first?.id
                    }
                }

                // Page dots
                if viewModel.insightFeed.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(viewModel.insightFeed) { insight in
                            Circle()
                                .fill(insight.id == insightPage ? DesignTokens.info : DesignTokens.textTertiary)
                                .frame(width: 6, height: 6)
                                .animation(.easeInOut(duration: 0.2), value: insightPage)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        } else if !viewModel.discoveryTips.isEmpty {
            DiscoveryCarousel(tips: viewModel.discoveryTips)
        }
    }

    // MARK: - Paywall Helper

    private static func paywallViewModel(from appState: AppState) -> OnboardingViewModel {
        let vm = OnboardingViewModel()
        if let user = appState.currentUser {
            vm.firstName = user.firstName
            vm.healthGoals = Set(user.healthGoals)
        }
        vm.generatedPlan = appState.activePlan
        return vm
    }
}

#Preview {
    let appState = AppState()
    appState.loadDemoData()
    return TodayScreen()
        .environment(appState)
}

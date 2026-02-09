import SwiftUI

struct HomeScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacing24) {
                    // Header
                    headerSection

                    // Wellbeing Score Card
                    if let checkIn = appState.todayCheckIn {
                        wellbeingCard(checkIn: checkIn)
                    } else {
                        emptyWellbeingCard
                    }

                    // Check-In CTA
                    checkInSection

                    // Today's Supplements
                    supplementsSection

                    // Latest Insight
                    if let insight = viewModel.latestInsight {
                        insightSection(insight: insight)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, DesignTokens.spacing32)
            }
        }
        .onAppear {
            viewModel.load(appState: appState)
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

                if appState.streak.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(DesignTokens.accentEnergy)
                        Text("\(appState.streak.currentStreak)")
                            .font(DesignTokens.dataMono)
                            .foregroundStyle(DesignTokens.accentEnergy)
                    }
                    .padding(.horizontal, DesignTokens.spacing8)
                    .padding(.vertical, DesignTokens.spacing4)
                    .background(DesignTokens.accentEnergy.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
                }
            }

            Text(viewModel.dateLabel.uppercased())
                .font(DesignTokens.labelMono)
                .tracking(1.2)
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(.top, DesignTokens.spacing8)
    }

    // MARK: - Wellbeing Card

    private func wellbeingCard(checkIn: DailyCheckIn) -> some View {
        VStack(spacing: DesignTokens.spacing16) {
            WellbeingScoreRing(
                sleepScore: checkIn.sleepScore,
                energyScore: checkIn.energyScore,
                clarityScore: checkIn.clarityScore,
                moodScore: checkIn.moodScore,
                gutScore: checkIn.gutScore
            )
        }
        .cardStyle()
    }

    private var emptyWellbeingCard: some View {
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
        .cardStyle()
    }

    // MARK: - Check-In

    private var checkInSection: some View {
        VStack(spacing: DesignTokens.spacing12) {
            if appState.hasCheckedInToday {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.positive)
                    Text("Checked in today")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                    Spacer()
                }
                .padding(DesignTokens.spacing16)
                .background(DesignTokens.positive.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            } else {
                VStack(spacing: DesignTokens.spacing12) {
                    SpectrumBar(height: 2)

                    Text("How are you feeling today?")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    CTAButton(title: "Check In", style: .primary) {
                        appState.showCheckInFlow = true
                    }
                }
                .cardStyle()
            }
        }
        .sheet(isPresented: Binding(
            get: { appState.showCheckInFlow },
            set: { appState.showCheckInFlow = $0 }
        )) {
            CheckInFlow()
                .environment(appState)
        }
    }

    // MARK: - Supplements

    private var supplementsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            HStack {
                Text("TODAY'S SUPPLEMENTS")
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)

                Spacer()

                if viewModel.totalSupplements > 0 {
                    Button("Take All") {
                        viewModel.takeAll()
                    }
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.info)
                }
            }

            if let plan = viewModel.activePlan {
                ForEach(plan.supplements) { supplement in
                    SupplementCard(
                        name: supplement.name,
                        dosage: supplement.dosage,
                        timing: supplement.timing.label,
                        isTaken: viewModel.supplementStates[supplement.id] ?? false,
                        onToggle: { viewModel.toggleSupplement(supplement.id) }
                    )
                }

                // Completion indicator
                HStack {
                    Text("\(viewModel.takenCount) of \(viewModel.totalSupplements) taken")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                    Spacer()
                }
            } else {
                Text("No plan generated yet")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textTertiary)
            }
        }
    }

    // MARK: - Insight

    private func insightSection(insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            Text("LATEST INSIGHT")
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            InsightCard(insight: insight)
        }
    }
}

#Preview {
    let appState = AppState()
    appState.currentUser = UserProfile(firstName: "Matt")
    appState.isOnboardingComplete = true

    return HomeScreen()
        .environment(appState)
}

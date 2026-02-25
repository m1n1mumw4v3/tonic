import SwiftUI

struct HomeScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(KnowledgeBaseProvider.self) private var kb
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacing24) {
                    // Header
                    headerSection

                    // Wellbeing Score Card + Check-In
                    if let checkIn = appState.todayCheckIn {
                        wellbeingCard(checkIn: checkIn)
                        checkInSection
                    } else if !appState.hasEverCheckedIn, let user = appState.currentUser {
                        BaselineWelcomeHero(user: user) {
                            appState.showCheckInFlow = true
                        }
                    } else {
                        emptyWellbeingCard
                        checkInSection
                    }

                    // Deep Profile Card
                    DeepProfileHomeCard()

                    // Insights or Discovery
                    insightsSection
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, DesignTokens.spacing32)
            }
        }
        .sheet(isPresented: Binding(
            get: { appState.showCheckInFlow },
            set: { appState.showCheckInFlow = $0 }
        )) {
            CheckInFlow()
                .environment(appState)
        }
        .onAppear {
            viewModel.load(appState: appState, kb: kb)
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
        .frame(maxWidth: .infinity)
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
        .frame(maxWidth: .infinity)
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
    }

    // MARK: - Insights Section

    @ViewBuilder
    private var insightsSection: some View {
        if !viewModel.insightFeed.isEmpty {
            insightFeedSection
        } else if !viewModel.discoveryTips.isEmpty {
            DiscoveryCarousel(tips: viewModel.discoveryTips)
        }
    }

    // MARK: - Insight Feed

    private var insightFeedSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Text("RECENT INSIGHTS")
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            ForEach(viewModel.insightFeed) { insight in
                InsightCard(insight: insight, onDismiss: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.dismissInsight(insight.id)
                    }
                })
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .onAppear {
                    viewModel.markInsightRead(insight.id)
                }
            }
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

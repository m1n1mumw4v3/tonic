import SwiftUI

struct CheckInFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(KnowledgeBaseProvider.self) private var kb
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CheckInViewModel()

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: DesignTokens.spacing8) {
                    let stepCount = appState.isSubscribed ? 3 : 2
                    ForEach(0..<stepCount, id: \.self) { step in
                        let progress = appState.isSubscribed ? viewModel.currentStep : (viewModel.currentStep == 0 ? 0 : 1)
                        Circle()
                            .fill(step <= progress ? DesignTokens.info : DesignTokens.textTertiary)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, DesignTokens.spacing16)

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case 0:
                        wellnessStep
                    case 1:
                        supplementStep
                    case 2:
                        completionStep
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            viewModel.kb = kb
            viewModel.initializeSupplements(from: appState.activePlan, existingCheckIn: appState.todayCheckIn)
            viewModel.loadTrailingAverages(from: appState)
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.currentStep > 0 && !viewModel.isComplete)
    }

    // MARK: - Step 1: Wellness Sliders

    private var wellnessStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.spacing24) {
                    Text("How are you feeling?")
                        .font(DesignTokens.headlineFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .padding(.top, DesignTokens.spacing24)

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
                }
                .padding(.horizontal, DesignTokens.spacing16)
            }

            Spacer()

            CTAButton(title: "Continue", style: .primary) {
                if appState.isSubscribed {
                    withAnimation {
                        viewModel.currentStep = 1
                    }
                } else {
                    viewModel.completeCheckIn(appState: appState)
                    withAnimation {
                        viewModel.currentStep = 2
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacing16)

            Spacer()
        }
        .padding(.bottom, DesignTokens.spacing32)
    }

    // MARK: - Step 2: Supplement Logging

    private var supplementStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.spacing24) {
                    // Dynamic title with streak badge
                    supplementHeader
                        .padding(.top, DesignTokens.spacing24)

                    if let plan = appState.activePlan {
                        SupplementLogList(
                            supplements: plan.supplements,
                            supplementStates: viewModel.supplementStates,
                            onToggle: { id in viewModel.toggleSupplement(id) },
                            onTakeAllSection: { ids in viewModel.takeAllByIDs(ids) },
                            amProgress: viewModel.amProgress,
                            pmProgress: viewModel.pmProgress,
                            amComplete: viewModel.amComplete,
                            pmComplete: viewModel.pmComplete
                        )
                    }

                    // Micro-reward card
                    if viewModel.allTaken, let content = viewModel.microRewardContent {
                        MicroRewardCard(content: content)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, DesignTokens.spacing24)
            }

            // Fixed bottom CTA area
            supplementCTA
        }
        .onChange(of: viewModel.allTaken) { _, allTaken in
            if allTaken && !viewModel.hasPlayedCompletionAnimation {
                viewModel.hasPlayedCompletionAnimation = true
                HapticManager.notification(.success)
                viewModel.generateMicroReward(appState: appState)
            }
        }
    }

    // MARK: - Supplement Header

    private var supplementHeader: some View {
        HStack(spacing: DesignTokens.spacing12) {
            Text(viewModel.supplementTitle)
                .font(DesignTokens.headlineFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .contentTransition(.interpolate)
                .animation(.easeInOut(duration: 0.3).delay(0.3), value: viewModel.allTaken)

            if appState.streak.currentStreak > 0 {
                streakBadge
            }

            Spacer()
        }
    }

    // MARK: - Streak Badge

    @ViewBuilder
    private var streakBadge: some View {
        let isForgiven = appState.streak.missedYesterday

        HStack(spacing: 4) {
            Image(systemName: isForgiven ? "exclamationmark.triangle" : "flame.fill")
                .font(.system(size: 11, weight: .medium))
            Text("\(appState.streak.currentStreak)")
                .font(DesignTokens.labelMono)
        }
        .foregroundStyle(isForgiven ? DesignTokens.textTertiary : DesignTokens.accentEnergy)
        .padding(.horizontal, DesignTokens.spacing8)
        .padding(.vertical, DesignTokens.spacing4)
        .background(
            Capsule()
                .fill((isForgiven ? DesignTokens.textTertiary : DesignTokens.accentEnergy).opacity(0.15))
        )
    }

    // MARK: - Supplement CTA

    private var supplementCTA: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [DesignTokens.bgDeepest.opacity(0), DesignTokens.bgDeepest],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)

            VStack(spacing: DesignTokens.spacing8) {
                if viewModel.allTaken {
                    // All taken state — completion button
                    Button {
                        viewModel.completeCheckIn(appState: appState)
                        withAnimation {
                            viewModel.currentStep = 2
                        }
                    } label: {
                        HStack(spacing: DesignTokens.spacing8) {
                            Text("All Taken")
                                .font(DesignTokens.ctaFont)
                                .tracking(0.32)
                            AnimatedCheckmark(isChecked: true, color: DesignTokens.textPrimary, size: 16)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(DesignTokens.bgElevated)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                .stroke(DesignTokens.borderDefault, lineWidth: 1)
                        )
                    }
                    .buttonStyle(CTAPressStyleInternal())
                    .transition(.opacity)
                } else {
                    // Take All button
                    CTAButton(title: "Take All", style: .primary) {
                        viewModel.takeAll(plan: appState.activePlan)
                    }
                    .transition(.opacity)

                    // Secondary label: "n of total logged"
                    if viewModel.takenCount >= 1, let plan = appState.activePlan {
                        Text("\(viewModel.takenCount) of \(plan.supplements.count) logged")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textTertiary)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: viewModel.takenCount)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.allTaken)
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.bottom, DesignTokens.spacing32)
            .background(DesignTokens.bgDeepest)
        }
    }

    // MARK: - Step 3: Completion

    private var completionStep: some View {
        VStack(spacing: DesignTokens.spacing24) {
            Spacer()

            if appState.isSubscribed {
                // Animated score
                WellbeingScoreRing(
                    sleepScore: Int(viewModel.sleepScore),
                    energyScore: Int(viewModel.energyScore),
                    clarityScore: Int(viewModel.clarityScore),
                    moodScore: Int(viewModel.moodScore),
                    gutScore: Int(viewModel.gutScore),
                    size: 160,
                    lineWidth: 12
                )
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignTokens.positive)
            }

            Text("Great check-in!")
                .font(DesignTokens.headlineFont)
                .foregroundStyle(DesignTokens.textPrimary)

            if appState.streak.currentStreak > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(DesignTokens.accentEnergy)
                    Text("\(appState.streak.currentStreak) day streak!")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.accentEnergy)
                }
            } else {
                Text("Come back tomorrow to build your streak")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            if appState.isSubscribed, let insight = viewModel.completionInsight {
                CompactInsightCard(insight: insight)
                    .padding(.horizontal, DesignTokens.spacing16)
            }

            if !appState.isSubscribed {
                VStack(spacing: DesignTokens.spacing12) {
                    Text("See how your supplements can improve these scores")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .multilineTextAlignment(.center)

                    CTAButton(title: "Unlock My Plan", style: .primary) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            appState.showPaywall = true
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
            }

            Spacer()

            CTAButton(title: "Done", style: .secondary) {
                dismiss()
            }
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.bottom, DesignTokens.spacing32)
        }
    }
}

// MARK: - Internal Press Style

private struct CTAPressStyleInternal: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    let state = AppState()
    state.isSubscribed = true
    state.activePlan = SupplementPlan(supplements: [
        // AM — Empty Stomach
        PlanSupplement(name: "L-Theanine", dosage: "200mg", timing: .emptyStomach),
        // AM — Morning
        PlanSupplement(name: "Omega-3 (EPA/DHA)", dosage: "1000mg", timing: .morning),
        PlanSupplement(name: "Vitamin B Complex", dosage: "1 cap", timing: .morning),
        // AM — With Food
        PlanSupplement(name: "Vitamin D3 + K2", dosage: "5000 IU", timing: .withFood),
        PlanSupplement(name: "Ashwagandha KSM-66", dosage: "600mg", timing: .withFood),
        PlanSupplement(name: "Coenzyme Q10", dosage: "200mg", timing: .withFood),
        // PM — Evening
        PlanSupplement(name: "Magnesium Glycinate", dosage: "400mg", timing: .evening),
        PlanSupplement(name: "Tart Cherry Extract", dosage: "500mg", timing: .evening),
        // PM — Bedtime
        PlanSupplement(name: "Melatonin", dosage: "0.5mg", timing: .bedtime),
    ])
    state.streak = UserStreak(currentStreak: 12, longestStreak: 12, lastCheckInDate: Date())

    return CheckInFlow()
        .environment(state)
}

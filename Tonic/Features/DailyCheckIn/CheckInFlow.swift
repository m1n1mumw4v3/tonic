import SwiftUI

struct CheckInFlow: View {
    @Environment(AppState.self) private var appState
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
                            .fill(step <= progress ? DesignTokens.info : DesignTokens.bgElevated)
                            .frame(width: 8, height: 8)
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
            viewModel.initializeSupplements(from: appState.activePlan)
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
                VStack(spacing: DesignTokens.spacing20) {
                    Text("Log your supplements")
                        .font(DesignTokens.headlineFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .padding(.top, DesignTokens.spacing24)

                    if let plan = appState.activePlan {
                        PillboxGrid(
                            supplements: plan.supplements,
                            supplementStates: viewModel.supplementStates,
                            onToggle: { id in viewModel.toggleSupplement(id) },
                            allJustCompleted: viewModel.allJustCompleted
                        )
                    }

                    // Footer: progress count + Took Everything
                    if let plan = appState.activePlan, !plan.supplements.isEmpty {
                        HStack {
                            Text("\(viewModel.takenCount) of \(plan.supplements.count) taken")
                                .font(DesignTokens.dataMono)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: viewModel.takenCount)

                            Spacer()

                            Button {
                                viewModel.takeAll(plan: plan)
                            } label: {
                                HStack(spacing: DesignTokens.spacing4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Took Everything")
                                        .font(DesignTokens.captionFont)
                                }
                                .foregroundStyle(DesignTokens.info)
                            }
                        }
                        .padding(.top, DesignTokens.spacing4)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, 100) // Space for fixed CTA
            }

            // Fixed CTA with gradient fade
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [DesignTokens.bgDeepest.opacity(0), DesignTokens.bgDeepest],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)

                CTAButton(title: "Done", style: .primary) {
                    viewModel.completeCheckIn(appState: appState)
                    withAnimation {
                        viewModel.currentStep = 2
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, DesignTokens.spacing32)
                .background(DesignTokens.bgDeepest)
            }
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

#Preview {
    CheckInFlow()
        .environment(AppState())
}

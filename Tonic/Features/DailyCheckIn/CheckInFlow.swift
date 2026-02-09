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
                    ForEach(0..<3) { step in
                        Circle()
                            .fill(step <= viewModel.currentStep ? DesignTokens.info : DesignTokens.bgElevated)
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
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.currentStep > 0 && !viewModel.isComplete)
    }

    // MARK: - Step 1: Wellness Sliders

    private var wellnessStep: some View {
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
                        highLabel: WellnessDimension.sleep.highLabel
                    )
                    WellnessSlider(
                        dimension: .energy,
                        value: $viewModel.energyScore,
                        lowLabel: WellnessDimension.energy.lowLabel,
                        highLabel: WellnessDimension.energy.highLabel
                    )
                    WellnessSlider(
                        dimension: .clarity,
                        value: $viewModel.clarityScore,
                        lowLabel: WellnessDimension.clarity.lowLabel,
                        highLabel: WellnessDimension.clarity.highLabel
                    )
                    WellnessSlider(
                        dimension: .mood,
                        value: $viewModel.moodScore,
                        lowLabel: WellnessDimension.mood.lowLabel,
                        highLabel: WellnessDimension.mood.highLabel
                    )
                    WellnessSlider(
                        dimension: .gut,
                        value: $viewModel.gutScore,
                        lowLabel: WellnessDimension.gut.lowLabel,
                        highLabel: WellnessDimension.gut.highLabel
                    )
                }

                CTAButton(title: "Continue", style: .primary) {
                    withAnimation {
                        viewModel.currentStep = 1
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.bottom, DesignTokens.spacing32)
        }
    }

    // MARK: - Step 2: Supplement Logging

    private var supplementStep: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacing20) {
                Text("Log your supplements")
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(.top, DesignTokens.spacing24)

                // Take All button
                if let plan = appState.activePlan, !plan.supplements.isEmpty {
                    Button {
                        viewModel.takeAll(plan: plan)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Took Everything")
                        }
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.info)
                        .padding(.vertical, DesignTokens.spacing8)
                    }
                }

                // Supplement cards
                if let plan = appState.activePlan {
                    ForEach(plan.supplements) { supplement in
                        SupplementCard(
                            name: supplement.name,
                            dosage: supplement.dosage,
                            timing: supplement.timing.label,
                            isTaken: viewModel.supplementStates[supplement.id] ?? false,
                            onToggle: { viewModel.toggleSupplement(supplement.id) }
                        )
                    }
                }

                // Count
                Text("\(viewModel.takenCount) of \(appState.activePlan?.supplements.count ?? 0) taken")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)

                CTAButton(title: "Done", style: .primary) {
                    viewModel.completeCheckIn(appState: appState)
                    withAnimation {
                        viewModel.currentStep = 2
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.bottom, DesignTokens.spacing32)
        }
    }

    // MARK: - Step 3: Completion

    private var completionStep: some View {
        VStack(spacing: DesignTokens.spacing24) {
            Spacer()

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

            Spacer()

            CTAButton(title: "Done", style: .secondary) {
                dismiss()
            }
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.bottom, DesignTokens.spacing32)
        }
        .onAppear {
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
}

#Preview {
    CheckInFlow()
        .environment(AppState())
}

import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()
    @State private var currentScreen: Int = 0
    @State private var navigatingForward: Bool = true

    private let totalScreens = 24

    private var skippedScreens: Set<Int> {
        var skipped = Set<Int>()
        if viewModel.healthKitProvidedSex { skipped.insert(7) }
        if viewModel.healthKitProvidedHeight { skipped.insert(8) }
        if viewModel.healthKitProvidedWeight { skipped.insert(9) }
        return skipped
    }

    private var activeScreens: [Int] {
        (0..<totalScreens).filter { !skippedScreens.contains($0) }
    }

    private var currentActiveIndex: Int {
        activeScreens.firstIndex(of: currentScreen) ?? 0
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button + progress bar
                if currentScreen > 0 && currentScreen < totalScreens - 3 {
                    HStack(spacing: DesignTokens.spacing12) {
                        Button(action: previousScreen) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        SpectrumBar(progress: CGFloat(currentActiveIndex) / CGFloat(activeScreens.count - 1))
                    }
                    .padding(.horizontal, DesignTokens.spacing16)
                    .padding(.top, DesignTokens.spacing8)
                }

                // Screen content
                Group {
                    switch currentScreen {
                    case 0:
                        WelcomeScreen(onContinue: nextScreen)
                    case 1:
                        ValuePropProblemScreen(onContinue: nextScreen)
                    case 2:
                        ValuePropComplexityScreen(onContinue: nextScreen)
                    case 3:
                        ValuePropSolutionScreen(onContinue: nextScreen)
                    case 4:
                        NameScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 5:
                        HealthKitScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 6:
                        AgeScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 7:
                        SexScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 8:
                        HeightScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 9:
                        WeightScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 10:
                        GoalsScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 11:
                        CurrentSuppsScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 12:
                        MedicationsScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 13:
                        AllergiesScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 14:
                        DietScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 15:
                        ExerciseScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 16:
                        CaffeineScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 17:
                        AlcoholScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 18:
                        StressScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 19:
                        BaselineScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 20:
                        NotificationReminderScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 21:
                        AIInterstitialScreen(viewModel: viewModel, onComplete: onInterstitialComplete)
                    case 22:
                        PlanRevealScreen(viewModel: viewModel, onConfirm: nextScreen)
                    case 23:
                        PaywallScreen(viewModel: viewModel, onSubscribe: completeOnboarding, onDismiss: dismissPaywall)
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: navigatingForward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: navigatingForward ? .leading : .trailing).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentScreen)
    }

    private func nextScreen() {
        navigatingForward = true
        withAnimation {
            if let nextIndex = activeScreens.firstIndex(where: { $0 > currentScreen }) {
                currentScreen = activeScreens[nextIndex]
            }
        }
    }

    private func skipToNameScreen() {
        navigatingForward = true
        withAnimation {
            currentScreen = 4
        }
    }

    private func previousScreen() {
        navigatingForward = false
        withAnimation {
            if let prevIndex = activeScreens.lastIndex(where: { $0 < currentScreen }) {
                currentScreen = activeScreens[prevIndex]
            }
        }
    }

    private func onInterstitialComplete() {
        // Build profile and generate plan, store on viewModel for the Plan Reveal screen
        let profile = viewModel.buildUserProfile()
        let engine = RecommendationEngine()
        let plan = engine.generatePlan(for: profile)
        viewModel.generatedPlan = plan
        nextScreen()
    }

    private func completeOnboarding() {
        let profile = viewModel.buildUserProfile()
        appState.currentUser = profile

        // Use the generated plan from the reveal screen, filtering out excluded supplements
        if var plan = viewModel.generatedPlan {
            plan.supplements = plan.supplements.filter(\.isIncluded)
            appState.activePlan = plan
        } else {
            // Fallback: generate fresh if somehow missing
            let engine = RecommendationEngine()
            let plan = engine.generatePlan(for: profile)
            appState.activePlan = plan
        }

        appState.isOnboardingComplete = true
    }

    private func dismissPaywall() {
        let profile = viewModel.buildUserProfile()
        appState.currentUser = profile

        if var plan = viewModel.generatedPlan {
            plan.supplements = plan.supplements.filter(\.isIncluded)
            appState.activePlan = plan
        } else {
            let engine = RecommendationEngine()
            let plan = engine.generatePlan(for: profile)
            appState.activePlan = plan
        }

        appState.isOnboardingComplete = true
        // isSubscribed remains false — user gets limited home screen
    }
}

#Preview {
    OnboardingFlow()
        .environment(AppState())
}

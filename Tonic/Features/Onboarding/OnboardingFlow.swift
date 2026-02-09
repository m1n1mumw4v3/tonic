import SwiftUI

struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()
    @State private var currentScreen: Int = 0
    @State private var navigatingForward: Bool = true

    private let totalScreens = 19

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button + progress bar
                if currentScreen > 0 && currentScreen < totalScreens - 2 {
                    HStack(spacing: DesignTokens.spacing12) {
                        Button(action: previousScreen) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        SpectrumBar(progress: CGFloat(currentScreen) / CGFloat(totalScreens - 1))
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
                        NameScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 2:
                        AgeScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 3:
                        SexScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 4:
                        HeightScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 5:
                        WeightScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 6:
                        GoalsScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 7:
                        CurrentSuppsScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 8:
                        MedicationsScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 9:
                        AllergiesScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 10:
                        DietScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 11:
                        ExerciseScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 12:
                        CaffeineScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 13:
                        AlcoholScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 14:
                        StressScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 15:
                        BaselineScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 16:
                        HealthKitScreen(viewModel: viewModel, onContinue: nextScreen)
                    case 17:
                        AIInterstitialScreen(viewModel: viewModel, onComplete: onInterstitialComplete)
                    case 18:
                        PlanRevealScreen(viewModel: viewModel, onConfirm: completeOnboarding)
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
            currentScreen = min(currentScreen + 1, totalScreens - 1)
        }
    }

    private func previousScreen() {
        navigatingForward = false
        withAnimation {
            currentScreen = max(currentScreen - 1, 0)
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
}

#Preview {
    OnboardingFlow()
        .environment(AppState())
}

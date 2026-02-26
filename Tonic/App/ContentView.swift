import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isCatalogLoading && !appState.supplementCatalog.isLoaded {
                catalogLoadingView
            } else if !appState.isOnboardingComplete {
                OnboardingFlow()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.isOnboardingComplete)
        .animation(.easeInOut(duration: 0.25), value: appState.supplementCatalog.isLoaded)
    }

    private var catalogLoadingView: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: DesignTokens.spacing16) {
                ProgressView()
                    .tint(DesignTokens.textSecondary)
                    .scaleEffect(1.2)

                Text("Loading your supplements...")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textTertiary)
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        TabView(selection: $state.selectedTab) {
            TodayScreen()
                .tabItem {
                    Label(AppTab.today.label, systemImage: AppTab.today.icon)
                }
                .tag(AppTab.today)

            InsightsScreen()
                .tabItem {
                    Label(AppTab.progress.label, systemImage: AppTab.progress.icon)
                }
                .tag(AppTab.progress)

            PlanScreen()
                .tabItem {
                    Label(AppTab.plan.label, systemImage: AppTab.plan.icon)
                }
                .tag(AppTab.plan)
        }
        .tint(DesignTokens.positive)
        .preferredColorScheme(.light)
    }
}

// MARK: - Placeholder Screens

struct SettingsPlaceholderScreen: View {
    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()
            VStack(spacing: DesignTokens.spacing16) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.textTertiary)
                Text("Settings")
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("Manage your account and preferences")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
    }
}

#Preview("Main Tabs") {
    let appState = AppState()
    appState.loadDemoData()
    return MainTabView()
        .environment(appState)
}

#Preview("Full App") {
    let appState = AppState()
    appState.loadDemoData()
    appState.isOnboardingComplete = false
    return ContentView()
        .environment(appState)
}

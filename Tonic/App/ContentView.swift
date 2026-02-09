import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingFlow()    
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.isOnboardingComplete)
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        TabView(selection: $state.selectedTab) {
            HomeScreen()
                .tabItem {
                    Label(AppTab.home.label, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

            PlanScreen()
                .tabItem {
                    Label(AppTab.plan.label, systemImage: AppTab.plan.icon)
                }
                .tag(AppTab.plan)

            ProgressPlaceholderScreen()
                .tabItem {
                    Label(AppTab.progress.label, systemImage: AppTab.progress.icon)
                }
                .tag(AppTab.progress)

            SettingsPlaceholderScreen()
                .tabItem {
                    Label(AppTab.settings.label, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(DesignTokens.info)
    }
}

// MARK: - Placeholder Screens (M4)

struct ProgressPlaceholderScreen: View {
    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()
            VStack(spacing: DesignTokens.spacing16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.textTertiary)
                Text("Progress")
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                Text("Track your trends over time")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
    }
}

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

#Preview {
    ContentView()
        .environment(AppState())
}

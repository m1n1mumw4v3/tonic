import SwiftUI

@main
struct EstusApp: App {
    @State private var appState = AppState()

    @State private var knowledgeBase = KnowledgeBaseProvider()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(knowledgeBase)
                .preferredColorScheme(.light)
                .task {
                    #if DEBUG
                    resetOnboardingForSimulatorIfRequested()
                    #endif

                    Task { await appState.authService.startListening() }

                    // Restore local data first — UserDefaults reads are instant
                    // and must complete before ContentView transitions to MainTabView
                    await appState.restoreSessionIfNeeded()

                    await knowledgeBase.loadKnowledgeBase()
                    async let catalog: Void = appState.loadSupplementCatalog()
                    async let meds: Void = appState.loadMedications()
                    _ = await (catalog, meds)

                    #if DEBUG
                    if CommandLine.arguments.contains("-bypassOnboarding") {
                        await appState.seedDevUserIfNeeded()
                    }
                    #endif

                    await appState.syncHealthKitIfEnabled()

                    if let profile = appState.currentUser {
                        await NotificationService.verifyAndReschedule(for: profile)
                    } else if let profile = try? LocalStorageService().getProfile() {
                        await NotificationService.verifyAndReschedule(for: profile)
                    }
                }
                .onOpenURL { url in
                    Task { await appState.authService.handleDeepLink(url) }
                }
        }
    }

    #if DEBUG
    /// Wipes locally-stored onboarding state when launched with `-resetOnboarding`.
    /// Off by default so simulator launches preserve state across runs.
    private func resetOnboardingForSimulatorIfRequested() {
        #if targetEnvironment(simulator)
        guard CommandLine.arguments.contains("-resetOnboarding") else { return }
        let defaults = UserDefaults.standard
        let keys = [
            "estus_onboarding_complete",
            "estus_user_profile",
            "estus_active_plan",
            "estus_check_ins",
            "estus_streak",
            "estus_insights",
            "estus_deep_profile"
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        #endif
    }
    #endif
}

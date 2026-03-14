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
                    Task { await appState.authService.startListening() }

                    // Restore local data first — UserDefaults reads are instant
                    // and must complete before ContentView transitions to MainTabView
                    await appState.restoreSessionIfNeeded()

                    await knowledgeBase.loadKnowledgeBase()
                    async let catalog: Void = appState.loadSupplementCatalog()
                    async let meds: Void = appState.loadMedications()
                    _ = await (catalog, meds)

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
}

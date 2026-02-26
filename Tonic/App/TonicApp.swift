import SwiftUI

@main
struct TonicApp: App {
    @State private var appState: AppState = {
        let state = AppState()
        state.loadDemoData()
        return state
    }()

    @State private var knowledgeBase = KnowledgeBaseProvider()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(knowledgeBase)
                .preferredColorScheme(.light)
                .task {
                    await knowledgeBase.loadKnowledgeBase()
                    await appState.loadSupplementCatalog()
                }
        }
    }
}

import SwiftUI

@main
struct TonicApp: App {
    @State private var appState: AppState = {
        let state = AppState()
        state.loadDemoData()
        return state
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}

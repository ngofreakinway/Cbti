import SwiftUI
import SwiftData

@main
struct QuietMindApp: App {
    var body: some Scene {
        WindowGroup {
            AppRoot()
        }
        .modelContainer(for: [SleepEntry.self, UserProfile.self])
    }
}

/// Bridge that wires the SwiftData ModelContext into our AppStore
struct AppRoot: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var store = AppStore()

    var body: some View {
        ContentView()
            .environmentObject(store)
            .onAppear { store.setup(context: modelContext) }
    }
}

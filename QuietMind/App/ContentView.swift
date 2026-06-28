import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if !store.isReady {
                SwiftUI.ProgressView()
                    .tint(.indigo)
            } else if store.profile == nil || !(store.profile?.onboardingCompleted ?? false) {
                OnboardingView()
                    .environmentObject(store)
            } else {
                MainTabView()
                    .environmentObject(store)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        TabView {
            TodayView()
                .environmentObject(store)
                .tabItem { Label("Today", systemImage: "moon.zzz.fill") }

            LearnView()
                .environmentObject(store)
                .tabItem { Label("Learn", systemImage: "book.fill") }

            PracticeView()
                .environmentObject(store)
                .tabItem { Label("Practice", systemImage: "heart.fill") }

            SleepProgressView()
                .environmentObject(store)
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .environmentObject(store)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.indigo)
    }
}

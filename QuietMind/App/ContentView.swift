import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if !store.isReady {
                SwiftUI.ProgressView()
            } else if store.profile == nil || !(store.profile?.onboardingCompleted ?? false) {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "moon.zzz.fill")
                }
                .tag(0)

            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(1)

            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "heart.fill")
                }
                .tag(2)

            SleepProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
        }
        .tint(.indigo)
    }
}

import SwiftUI

struct CoachingView: View {
    @EnvironmentObject var store: AppStore
    @State private var linkedExercise: String?
    @State private var showProgress = false

    private var insights: [SleepInsight] {
        guard let profile = store.profile else { return [] }
        return SleepCoachEngine.insights(
            entries: store.sleepEntries,
            profile: profile,
            programDay: store.programDayNumber
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if insights.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headerCard
                            ForEach(insights) { insight in
                                InsightCard(insight: insight) { action in
                                    handle(action)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Coach")
            .sheet(item: Binding(
                get: { linkedExercise.map { ExerciseTarget(id: $0) } },
                set: { linkedExercise = $0?.id }
            )) { target in
                ExerciseSheet(exerciseID: target.id)
            }
            .navigationDestination(isPresented: $showProgress) {
                Text("Progress").navigationTitle("Progress")
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.24, green: 0.18, blue: 0.60), Color(red: 0.50, green: 0.28, blue: 0.78)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("CBT-I Coach")
                    .font(.headline)
                Text("Personalized insights based on your sleep diary")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 64))
                .foregroundStyle(.indigo.opacity(0.5))
            Text("Log 3 nights to unlock coaching")
                .font(.title3.bold())
            Text("Once you have a few diary entries, your coach will analyze your sleep patterns and give you personalized CBT-I guidance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func handle(_ action: SleepInsight.InsightAction) {
        switch action {
        case .openExercise(let id):
            linkedExercise = id
        case .openProgress, .openSettings:
            break
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: SleepInsight
    let onAction: (SleepInsight.InsightAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(insight.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: insight.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(insight.color)
                }
                Text(insight.title)
                    .font(.headline)
                Spacer()
                categoryTag
            }

            Text(insight.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let label = insight.actionLabel, let target = insight.actionTarget {
                Button {
                    onAction(target)
                } label: {
                    HStack(spacing: 6) {
                        Text(label)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(insight.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(insight.color.opacity(0.2), lineWidth: 1)
        )
    }

    private var categoryTag: some View {
        Text(categoryLabel)
            .font(.caption2.weight(.medium))
            .foregroundStyle(insight.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(insight.color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var categoryLabel: String {
        switch insight.category {
        case .windowAdjustment: return "WINDOW"
        case .stimulusControl:  return "STIMULUS"
        case .progress:         return "PROGRESS"
        case .hygiene:          return "HYGIENE"
        case .cognitive:        return "COGNITIVE"
        case .compliance:       return "DIARY"
        }
    }
}

// MARK: - Supporting types / sheets

private struct ExerciseTarget: Identifiable { let id: String }

private struct ExerciseSheet: View {
    let exerciseID: String

    var body: some View {
        NavigationStack {
            Group {
                switch exerciseID {
                case "breathing":      BreathingExerciseView()
                case "pmr":            PMRView()
                case "thought_record": ThoughtRecordView()
                case "worry_time":     WorryTimeView()
                default:
                    ContentUnavailableView("Exercise not found", systemImage: "questionmark.circle")
                }
            }
        }
    }
}

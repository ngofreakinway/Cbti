import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var store: AppStore

    @State private var destination: PracticeDestination?

    enum PracticeDestination: String, Hashable {
        case breathing, pmr, thoughtRecord, worryTime
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Evidence-based exercises from the workbook. Practice them during the day so they're easy to use at night.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ExerciseCard(
                        title: "Diaphragmatic Breathing",
                        subtitle: "Calm the nervous system in 5 minutes",
                        icon: "wind",
                        color: .cyan,
                        duration: "3–10 min",
                        tag: "Anxiety · Arousal"
                    ) { destination = .breathing }

                    ExerciseCard(
                        title: "Progressive Muscle Relaxation",
                        subtitle: "Systematically release tension from head to toe",
                        icon: "figure.mind.and.body",
                        color: .purple,
                        duration: "15–20 min",
                        tag: "Anxiety · Pain"
                    ) { destination = .pmr }

                    ExerciseCard(
                        title: "Thought Record",
                        subtitle: "Examine and reframe unhelpful sleep thoughts",
                        icon: "pencil.and.list.clipboard",
                        color: .red,
                        duration: "10 min",
                        tag: "Cognitive · Depression · Anxiety"
                    ) { destination = .thoughtRecord }

                    ExerciseCard(
                        title: "Scheduled Worry Time",
                        subtitle: "Contain worry to a designated daytime window",
                        icon: "timer",
                        color: .orange,
                        duration: "20 min/day",
                        tag: "Anxiety"
                    ) { destination = .worryTime }
                }
                .padding(.vertical)
            }
            .navigationTitle("Practice")
            .navigationDestination(item: $destination) { dest in
                switch dest {
                case .breathing: BreathingExerciseView()
                case .pmr: PMRView()
                case .thoughtRecord: ThoughtRecordView()
                case .worryTime: WorryTimeView()
                }
            }
        }
    }
}

private struct ExerciseCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let duration: String
    let tag: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 52, height: 52)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Label(duration, systemImage: "clock")
                            .font(.caption2).foregroundStyle(color)
                        Text("·").foregroundStyle(.secondary)
                        Text(tag).font(.caption2).foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(color)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

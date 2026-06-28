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
                VStack(spacing: 14) {
                    Text("Evidence-based exercises from the CBT-I workbook. Practice during the day so they're effortless at night.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)

                    ExerciseCard(
                        title: "Diaphragmatic Breathing",
                        subtitle: "Activate your parasympathetic nervous system",
                        description: "Slow, deep breathing that calms physiological arousal in minutes. Use before bed or after waking at night.",
                        icon: "wind",
                        gradient: [Color(red: 0.1, green: 0.65, blue: 0.75), Color(red: 0.0, green: 0.50, blue: 0.62)],
                        duration: "3–10 min",
                        tags: ["Anxiety", "Arousal"]
                    ) { destination = .breathing }

                    ExerciseCard(
                        title: "Progressive Muscle Relaxation",
                        subtitle: "Systematically release tension from head to toe",
                        description: "Tense and release 8 muscle groups to achieve deep physical relaxation and reduce pain-related arousal.",
                        icon: "figure.mind.and.body",
                        gradient: [Color(red: 0.50, green: 0.22, blue: 0.78), Color(red: 0.38, green: 0.14, blue: 0.62)],
                        duration: "15–20 min",
                        tags: ["Anxiety", "Pain"]
                    ) { destination = .pmr }

                    ExerciseCard(
                        title: "Thought Record",
                        subtitle: "Examine and reframe unhelpful sleep thoughts",
                        description: "Challenge the catastrophizing thoughts that keep your brain in threat mode. Build more balanced, realistic perspectives.",
                        icon: "pencil.and.list.clipboard",
                        gradient: [Color(red: 0.88, green: 0.26, blue: 0.38), Color(red: 0.70, green: 0.16, blue: 0.26)],
                        duration: "10 min",
                        tags: ["Cognitive", "Depression", "Anxiety"]
                    ) { destination = .thoughtRecord }

                    ExerciseCard(
                        title: "Scheduled Worry Time",
                        subtitle: "Contain worry to a designated daytime window",
                        description: "Capture and defer worries to a fixed daily window so they don't intrude at bedtime. Spend 20 minutes processing them intentionally.",
                        icon: "timer",
                        gradient: [Color(red: 0.95, green: 0.55, blue: 0.10), Color(red: 0.82, green: 0.40, blue: 0.02)],
                        duration: "20 min/day",
                        tags: ["Anxiety"]
                    ) { destination = .worryTime }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Practice")
            .navigationDestination(item: $destination) { dest in
                switch dest {
                case .breathing:    BreathingExerciseView()
                case .pmr:          PMRView()
                case .thoughtRecord: ThoughtRecordView()
                case .worryTime:    WorryTimeView()
                }
            }
        }
    }
}

// MARK: - Exercise Card

private struct ExerciseCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let gradient: [Color]
    let duration: String
    let tags: [String]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .frame(width: 58, height: 58)
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Label(duration, systemImage: "clock")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(gradient.last ?? .indigo)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle((gradient.last ?? .indigo).opacity(0.8))
                }
                .padding(16)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                Divider().padding(.horizontal, 16)

                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(gradient.last ?? .indigo)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background((gradient.last ?? .indigo).opacity(0.10))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.easeInOut(duration: 0.15)) { isPressed = false } }
        )
    }
}

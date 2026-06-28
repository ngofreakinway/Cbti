import SwiftUI

struct WorryTimeView: View {
    @State private var worries: [WorryItem] = []
    @State private var newWorry = ""
    @State private var isInWorrySession = false
    @State private var sessionTimeRemaining = 20 * 60
    @State private var timer: Timer?

    struct WorryItem: Identifiable {
        let id = UUID()
        var text: String
        var actionable: Bool = false
        var actionPlan: String = ""
        var deferred: Bool = true
    }

    var body: some View {
        // No NavigationStack here — this view is pushed inside PracticeView's NavigationStack
        VStack(spacing: 0) {
            if isInWorrySession {
                worrySession
            } else {
                deferralInbox
            }
        }
        .navigationTitle("Scheduled Worry")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTimer() }
    }

    // MARK: - Deferral Inbox

    private var deferralInbox: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Worry Inbox", systemImage: "tray.fill")
                    .font(.headline)
                Text("When a worry surfaces outside your worry window, capture it here and let it go until your scheduled time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Write a worry to defer...", text: $newWorry)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                    Button(action: addWorry) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    .disabled(newWorry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))

            List {
                if worries.isEmpty {
                    ContentUnavailableView(
                        "No deferred worries",
                        systemImage: "checkmark.circle",
                        description: Text("Capture worries here as they arise. Process them during your worry session.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(worries) { worry in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(worry.text)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .onDelete { worries.remove(atOffsets: $0) }
                }
            }
            .listStyle(.plain)

            Divider()

            VStack(spacing: 12) {
                Text("Run your 20-minute worry window once per day, same time each day (not within 3h of bed).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: startWorrySession) {
                    Label("Start Worry Session (20 min)", systemImage: "timer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    // MARK: - Worry Session

    private var worrySession: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text(formatTime(sessionTimeRemaining))
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(.orange)
                Spacer()
                Button("End Session") { endSession() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            SwiftUI.ProgressView(value: Double(20 * 60 - sessionTimeRemaining), total: Double(20 * 60))
                .tint(.orange)
                .padding(.horizontal)

            Divider()

            if worries.isEmpty {
                ContentUnavailableView(
                    "No worries captured",
                    systemImage: "tray",
                    description: Text("Think about what's on your mind and address each item.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(worries.indices, id: \.self) { i in
                            WorryCard(worry: $worries[i])
                        }
                    }
                    .padding()
                }
            }

            Spacer()

            Text("For each worry: can you act on it? If yes, make a plan. If no, practice acceptance — acknowledge the uncertainty and set it aside.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
    }

    private struct WorryCard: View {
        @Binding var worry: WorryItem

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(worry.text)
                    .font(.subheadline.bold())

                HStack {
                    Text("Can I do something about this?")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Toggle("", isOn: $worry.actionable)
                        .labelsHidden()
                        .tint(.orange)
                }

                if worry.actionable {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Action plan:")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("What will I do? When?", text: $worry.actionPlan, axis: .vertical)
                            .font(.caption)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                } else {
                    Text("Practice acceptance: \"I cannot control this. I can acknowledge the uncertainty and return my attention to the present.\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }

                Button(action: { worry.deferred = false }) {
                    Label(
                        worry.deferred ? "Mark addressed" : "Addressed",
                        systemImage: worry.deferred ? "checkmark.circle" : "checkmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(worry.deferred ? .secondary : .green)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Actions

    private func addWorry() {
        let text = newWorry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        worries.append(WorryItem(text: text))
        newWorry = ""
    }

    private func startWorrySession() {
        isInWorrySession = true
        sessionTimeRemaining = 20 * 60
        // Timer is scheduled from the main thread (button action), so its closure
        // fires on the main RunLoop — safe to mutate @State directly.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if sessionTimeRemaining > 0 {
                sessionTimeRemaining -= 1
            } else {
                endSession()
            }
        }
    }

    private func endSession() {
        stopTimer()
        isInWorrySession = false
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

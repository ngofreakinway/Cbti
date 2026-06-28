import SwiftUI

struct PMRView: View {
    @State private var currentGroup = -1  // -1 = intro
    @State private var phase: PMRPhase = .tense
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var isRunning = false

    enum PMRPhase {
        case tense, release
        var label: String { self == .tense ? "Tense" : "Release & notice" }
        var color: Color { self == .tense ? .red : .green }
        var seconds: Int { self == .tense ? 6 : 25 }
    }

    let muscleGroups: [(name: String, instruction: String)] = [
        ("Feet & Calves", "Curl your toes downward and tense your calves."),
        ("Thighs", "Squeeze your thighs together tightly."),
        ("Abdomen", "Tighten your stomach muscles as if bracing for a punch."),
        ("Hands & Forearms", "Make tight fists and tense your forearms."),
        ("Upper Arms", "Flex your biceps and triceps."),
        ("Shoulders", "Shrug your shoulders up toward your ears."),
        ("Neck", "Gently tilt your head back and press it against a surface."),
        ("Face", "Scrunch your face: close eyes tight, clench jaw, wrinkle nose.")
    ]

    var isComplete: Bool { currentGroup >= muscleGroups.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if currentGroup == -1 {
                    introView
                } else if isComplete {
                    completeView
                } else {
                    exerciseView
                }
            }
            .padding(20)
        }
        .navigationTitle("PMR")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(.purple)

            VStack(spacing: 8) {
                Text("Progressive Muscle Relaxation")
                    .font(.title2.bold())
                Text("~20 minutes · 8 muscle groups")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("How it works")
                    .font(.headline)
                Text("You'll tense each muscle group for 6 seconds, then release and spend 25 seconds noticing the contrast. The tension–release cycle creates deeper relaxation than relaxing alone.")
                    .foregroundStyle(.secondary)
                Text("Find a comfortable position — lying down or seated. Close your eyes after reading each instruction.")
                    .foregroundStyle(.secondary)
            }

            ForEach(muscleGroups.indices, id: \.self) { i in
                HStack {
                    Text("\(i + 1). \(muscleGroups[i].name)")
                        .font(.subheadline)
                    Spacer()
                }
            }

            Button(action: startSession) {
                Text("Begin Session")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Exercise

    private var exerciseView: some View {
        VStack(spacing: 28) {
            // Progress
            HStack(spacing: 3) {
                ForEach(muscleGroups.indices, id: \.self) { i in
                    Capsule()
                        .fill(i < currentGroup ? Color.green : (i == currentGroup ? Color.purple : Color(.systemGray5)))
                        .frame(height: 4)
                }
            }

            Text("\(currentGroup + 1) of \(muscleGroups.count)")
                .font(.caption).foregroundStyle(.secondary)

            Text(muscleGroups[currentGroup].name)
                .font(.title.bold())

            Text(muscleGroups[currentGroup].instruction)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            // Timer circle
            ZStack {
                Circle()
                    .fill(phase.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                VStack(spacing: 4) {
                    Text(phase.label)
                        .font(.headline)
                        .foregroundStyle(phase.color)
                    Text("\(countdown)")
                        .font(.system(size: 52, weight: .thin, design: .rounded))
                        .contentTransition(.numericText())
                }
            }

            if phase == .release {
                Text("Notice the warmth, heaviness, and difference between tension and release.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)
            Text("Session Complete")
                .font(.title.bold())
            Text("Take a few natural breaths. Notice the overall sense of relaxation in your body. When ready, open your eyes slowly.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: reset) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Logic

    private func startSession() {
        currentGroup = 0
        runTense()
    }

    private func runTense() {
        phase = .tense
        countdown = PMRPhase.tense.seconds
        tick(seconds: PMRPhase.tense.seconds) { runRelease() }
    }

    private func runRelease() {
        phase = .release
        countdown = PMRPhase.release.seconds
        tick(seconds: PMRPhase.release.seconds) {
            currentGroup += 1
            if currentGroup < muscleGroups.count { runTense() }
        }
    }

    private func tick(seconds: Int, completion: @escaping () -> Void) {
        countdown = seconds
        var remaining = seconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            remaining -= 1
            withAnimation { countdown = remaining }
            if remaining <= 0 {
                t.invalidate()
                completion()
            }
        }
    }

    private func reset() {
        currentGroup = -1
        timer?.invalidate()
    }
}

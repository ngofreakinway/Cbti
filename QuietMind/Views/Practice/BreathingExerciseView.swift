import SwiftUI

struct BreathingExerciseView: View {
    @State private var phase: BreathPhase = .ready
    @State private var cycleCount = 0
    @State private var totalCycles = 4
    @State private var selectedPattern: BreathPattern = .fourSevenEight
    @State private var countdown = 0
    @State private var timer: Timer?
    @State private var animationScale: CGFloat = 1.0
    @State private var isRunning = false

    enum BreathPhase: String {
        case ready = "Press Start"
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale slowly"
        case done = "Complete"

        var color: Color {
            switch self {
            case .inhale: return .cyan
            case .hold: return .indigo
            case .exhale: return .teal
            case .done: return .green
            default: return .secondary
            }
        }
    }

    enum BreathPattern: String, CaseIterable, Identifiable {
        case fourSevenEight = "4-7-8"
        case boxBreathing = "Box (4-4-4-4)"
        case relaxing = "Relaxing (4-0-8)"

        var id: String { rawValue }
        var inhale: Int { switch self { case .fourSevenEight: return 4; case .boxBreathing: return 4; case .relaxing: return 4 } }
        var hold: Int { switch self { case .fourSevenEight: return 7; case .boxBreathing: return 4; case .relaxing: return 0 } }
        var exhale: Int { switch self { case .fourSevenEight: return 8; case .boxBreathing: return 4; case .relaxing: return 8 } }
        var description: String { switch self {
            case .fourSevenEight: return "Most effective for anxiety"
            case .boxBreathing: return "Used by Navy SEALs for stress"
            case .relaxing: return "Simple, calming"
        }}
    }

    var body: some View {
        VStack(spacing: 32) {
            // Pattern picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Pattern").font(.caption).foregroundStyle(.secondary)
                Picker("Pattern", selection: $selectedPattern) {
                    ForEach(BreathPattern.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isRunning)
                Text(selectedPattern.description)
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            // Animated circle
            ZStack {
                Circle()
                    .fill(phase.color.opacity(0.08))
                    .frame(width: 240, height: 240)
                Circle()
                    .stroke(phase.color.opacity(0.3), lineWidth: 2)
                    .frame(width: 240, height: 240)
                Circle()
                    .fill(phase.color.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .scaleEffect(animationScale)
                    .animation(.easeInOut(duration: Double(activeSeconds)), value: animationScale)

                VStack(spacing: 4) {
                    Text(phase.rawValue)
                        .font(.title2.bold())
                        .foregroundStyle(phase.color)
                    if isRunning && phase != .done {
                        Text("\(countdown)")
                            .font(.system(size: 48, weight: .thin, design: .rounded))
                            .contentTransition(.numericText())
                    }
                }
            }

            // Cycle counter
            if isRunning || phase == .done {
                HStack(spacing: 8) {
                    ForEach(0..<totalCycles, id: \.self) { i in
                        Circle()
                            .fill(i < cycleCount ? Color.cyan : Color(.systemGray5))
                            .frame(width: 10, height: 10)
                    }
                }
            }

            Spacer()

            // Cycles selector
            if !isRunning {
                HStack {
                    Text("Cycles")
                    Spacer()
                    Stepper("\(totalCycles)", value: $totalCycles, in: 2...12)
                }
                .padding(.horizontal)
            }

            // Control button
            Button(action: isRunning ? stop : start) {
                Text(phase == .done ? "Restart" : (isRunning ? "Stop" : "Start"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color(.systemGray4) : Color.cyan)
                    .foregroundStyle(isRunning ? .primary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle("Breathing")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stop() }
    }

    private var activeSeconds: Int {
        switch phase {
        case .inhale: return selectedPattern.inhale
        case .hold: return selectedPattern.hold
        case .exhale: return selectedPattern.exhale
        default: return 1
        }
    }

    private func start() {
        phase = .ready
        cycleCount = 0
        isRunning = true
        runInhale()
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        animationScale = 1.0
        phase = .ready
    }

    private func runInhale() {
        phase = .inhale
        countdown = selectedPattern.inhale
        animationScale = 1.3
        tick(seconds: selectedPattern.inhale) {
            if selectedPattern.hold > 0 { runHold() } else { runExhale() }
        }
    }

    private func runHold() {
        phase = .hold
        countdown = selectedPattern.hold
        tick(seconds: selectedPattern.hold) { runExhale() }
    }

    private func runExhale() {
        phase = .exhale
        countdown = selectedPattern.exhale
        animationScale = 1.0
        tick(seconds: selectedPattern.exhale) {
            cycleCount += 1
            if cycleCount >= totalCycles {
                phase = .done
                isRunning = false
            } else {
                runInhale()
            }
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
}

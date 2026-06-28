import SwiftUI

struct MorningCheckInView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let entry: SleepEntry

    @State private var bedTime: Date
    @State private var lightsOutTime: Date
    @State private var sleepOnsetMinutes: Double
    @State private var wakeAfterSleepOnset: Double
    @State private var numberOfAwakenings: Double
    @State private var finalWakeTime: Date
    @State private var outOfBedTime: Date
    @State private var sleepQuality: Int
    @State private var morningMood: Int
    @State private var energyLevel: Int

    init(entry: SleepEntry) {
        self.entry = entry
        _bedTime = State(initialValue: entry.bedTime)
        _lightsOutTime = State(initialValue: entry.lightsOutTime)
        _sleepOnsetMinutes = State(initialValue: Double(entry.sleepOnsetMinutes))
        _wakeAfterSleepOnset = State(initialValue: Double(entry.wakeAfterSleepOnset))
        _numberOfAwakenings = State(initialValue: Double(entry.numberOfAwakenings))
        _finalWakeTime = State(initialValue: entry.finalWakeTime)
        _outOfBedTime = State(initialValue: entry.outOfBedTime)
        _sleepQuality = State(initialValue: entry.sleepQuality)
        _morningMood = State(initialValue: entry.morningMood)
        _energyLevel = State(initialValue: entry.energyLevel)
    }

    var estimatedTST: Int {
        let tib = max(0, Int(outOfBedTime.timeIntervalSince(bedTime) / 60))
        return max(0, tib - Int(sleepOnsetMinutes) - Int(wakeAfterSleepOnset))
    }

    var estimatedSE: Double {
        let tib = max(1, Int(outOfBedTime.timeIntervalSince(bedTime) / 60))
        return Double(estimatedTST) / Double(tib) * 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Complete this log as soon as you wake up, while the night is fresh. Estimate — don't obsess over exact times.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Time in Bed") {
                    DatePicker("Got into bed", selection: $bedTime, displayedComponents: .hourAndMinute)
                    DatePicker("Lights out / tried to sleep", selection: $lightsOutTime, displayedComponents: .hourAndMinute)
                }

                Section("During the Night") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How long to fall asleep?")
                        Text("\(Int(sleepOnsetMinutes)) minutes")
                            .font(.headline).foregroundStyle(.indigo)
                        Slider(value: $sleepOnsetMinutes, in: 0...180, step: 5)
                            .tint(.indigo)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total time awake during the night")
                        Text("\(Int(wakeAfterSleepOnset)) minutes")
                            .font(.headline).foregroundStyle(.orange)
                        Slider(value: $wakeAfterSleepOnset, in: 0...240, step: 5)
                            .tint(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Number of awakenings")
                        Text("\(Int(numberOfAwakenings))")
                            .font(.headline).foregroundStyle(.secondary)
                        Slider(value: $numberOfAwakenings, in: 0...20, step: 1)
                    }
                }

                Section("Morning") {
                    DatePicker("Final wake time", selection: $finalWakeTime, displayedComponents: .hourAndMinute)
                    DatePicker("Got out of bed", selection: $outOfBedTime, displayedComponents: .hourAndMinute)
                }

                Section("Ratings") {
                    RatingRow(label: "Sleep quality", value: $sleepQuality, low: "Poor", high: "Excellent")
                    RatingRow(label: "Morning mood", value: $morningMood, low: "Very low", high: "Great")
                    RatingRow(label: "Energy level", value: $energyLevel, low: "Exhausted", high: "Energized")
                }

                Section("Summary (estimated)") {
                    HStack {
                        Label("Total Sleep", systemImage: "moon.fill")
                        Spacer()
                        Text(SleepCalculator.formatMinutes(estimatedTST))
                            .foregroundStyle(.indigo).bold()
                    }
                    HStack {
                        Label("Sleep Efficiency", systemImage: "percent")
                        Spacer()
                        Text(String(format: "%.0f%%", estimatedSE))
                            .foregroundStyle(estimatedSE >= 85 ? .green : .red).bold()
                    }
                }
            }
            .navigationTitle("Morning Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                }
            }
        }
    }

    private func save() {
        entry.bedTime = bedTime
        entry.lightsOutTime = lightsOutTime
        entry.sleepOnsetMinutes = Int(sleepOnsetMinutes)
        entry.wakeAfterSleepOnset = Int(wakeAfterSleepOnset)
        entry.numberOfAwakenings = Int(numberOfAwakenings)
        entry.finalWakeTime = finalWakeTime
        entry.outOfBedTime = outOfBedTime
        entry.sleepQuality = sleepQuality
        entry.morningMood = morningMood
        entry.energyLevel = energyLevel
        entry.morningCompleted = true
        store.save(entry)
        dismiss()
    }
}

// MARK: - Rating Row

struct RatingRow: View {
    let label: String
    @Binding var value: Int
    let low: String
    let high: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
            HStack(spacing: 8) {
                Text(low).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                ForEach(1...5, id: \.self) { i in
                    Button(action: { value = i }) {
                        Circle()
                            .fill(i <= value ? Color.indigo : Color(.systemGray5))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("\(i)").font(.caption2).foregroundStyle(i <= value ? .white : .secondary)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Text(high).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

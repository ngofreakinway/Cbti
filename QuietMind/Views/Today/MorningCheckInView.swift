import SwiftUI
import HealthKit

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

    @State private var healthSourceFields: Set<String> = []
    @State private var isLoadingHealth = false
    @State private var healthError: String?

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

    // MARK: - Midnight-crossing helpers
    // DatePicker(.hourAndMinute) keeps everything on the same calendar date.
    // If the user sets bed at 11 PM and out-of-bed at 7 AM, both land on "today"
    // so outOfBedTime < bedTime. We add one day whenever that happens.

    private func adjusted(_ time: Date, after reference: Date) -> Date {
        guard time < reference else { return time }
        return Calendar.current.date(byAdding: .day, value: 1, to: time) ?? time
    }

    private var adjustedOutOfBed: Date { adjusted(outOfBedTime, after: bedTime) }
    private var adjustedLightsOut: Date { adjusted(lightsOutTime, after: bedTime) }
    private var adjustedFinalWake: Date { adjusted(finalWakeTime, after: bedTime) }

    var estimatedTIB: Int {
        max(0, Int(adjustedOutOfBed.timeIntervalSince(bedTime) / 60))
    }

    var estimatedTST: Int {
        max(0, estimatedTIB - Int(sleepOnsetMinutes) - Int(wakeAfterSleepOnset))
    }

    var estimatedSE: Double {
        guard estimatedTIB > 0 else { return 0 }
        return Double(estimatedTST) / Double(estimatedTIB) * 100
    }

    var body: some View {
        NavigationStack {
            Form {
                // HealthKit banner
                if isLoadingHealth {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView().tint(.pink)
                            Text("Reading Apple Health…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } else if !healthSourceFields.isEmpty {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pre-filled from Apple Health")
                                    .font(.subheadline.weight(.medium))
                                Text("Review and adjust anything that looks wrong.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else if let error = healthError {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } else if HKHealthStore.isHealthDataAvailable() {
                    Section {
                        Text("Complete this log as soon as you wake up, while the night is fresh. Estimate — don't obsess over exact times.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        Text("Complete this log as soon as you wake up, while the night is fresh. Estimate — don't obsess over exact times.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Time in Bed") {
                    HealthLabeledPicker(
                        label: "Got into bed",
                        selection: $bedTime,
                        fromHealth: healthSourceFields.contains("bedTime")
                    )
                    HealthLabeledPicker(
                        label: "Lights out / tried to sleep",
                        selection: $lightsOutTime,
                        fromHealth: healthSourceFields.contains("lightsOutTime")
                    )
                }

                Section("During the Night") {
                    VStack(alignment: .leading, spacing: 4) {
                        HealthFieldLabel(label: "How long to fall asleep?", fromHealth: healthSourceFields.contains("sleepOnsetMinutes"))
                        Text("\(Int(sleepOnsetMinutes)) minutes")
                            .font(.headline).foregroundStyle(.indigo)
                        Slider(value: $sleepOnsetMinutes, in: 0...180, step: 5)
                            .tint(.indigo)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HealthFieldLabel(label: "Total time awake during the night", fromHealth: healthSourceFields.contains("wakeAfterSleepOnset"))
                        Text("\(Int(wakeAfterSleepOnset)) minutes")
                            .font(.headline).foregroundStyle(.orange)
                        Slider(value: $wakeAfterSleepOnset, in: 0...240, step: 5)
                            .tint(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HealthFieldLabel(label: "Number of awakenings", fromHealth: healthSourceFields.contains("numberOfAwakenings"))
                        Text("\(Int(numberOfAwakenings))")
                            .font(.headline).foregroundStyle(.secondary)
                        Slider(value: $numberOfAwakenings, in: 0...20, step: 1)
                    }
                }

                Section("Morning") {
                    HealthLabeledPicker(
                        label: "Final wake time",
                        selection: $finalWakeTime,
                        fromHealth: healthSourceFields.contains("finalWakeTime")
                    )
                    HealthLabeledPicker(
                        label: "Got out of bed",
                        selection: $outOfBedTime,
                        fromHealth: healthSourceFields.contains("outOfBedTime")
                    )
                }

                Section("Ratings") {
                    RatingRow(label: "Sleep quality", value: $sleepQuality, low: "Poor", high: "Excellent")
                    RatingRow(label: "Morning mood", value: $morningMood, low: "Very low", high: "Great")
                    RatingRow(label: "Energy level", value: $energyLevel, low: "Exhausted", high: "Energized")
                }

                Section("Summary (estimated)") {
                    HStack {
                        Label("Time in Bed", systemImage: "bed.double.fill")
                        Spacer()
                        Text(SleepCalculator.formatMinutes(estimatedTIB))
                            .foregroundStyle(.secondary).bold()
                    }
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
                            .foregroundStyle(estimatedSE >= 85 ? Color.green : Color.red).bold()
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
            .task { await fetchHealthData() }
        }
    }

    // MARK: - HealthKit fetch

    private func fetchHealthData() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        isLoadingHealth = true
        let granted = await HealthKitManager.shared.requestAuthorization()
        guard granted else {
            isLoadingHealth = false
            healthError = "Apple Health access not granted. Fill in manually."
            return
        }
        let data = await HealthKitManager.shared.fetchLastNight()
        isLoadingHealth = false

        guard !data.sourceFields.isEmpty else {
            healthError = "No sleep data found in Apple Health for last night."
            return
        }

        // Apply values from HealthKit
        if let v = data.bedTime         { bedTime = v }
        if let v = data.lightsOutTime   { lightsOutTime = v }
        if let v = data.outOfBedTime    { outOfBedTime = v }
        if let v = data.finalWakeTime   { finalWakeTime = v }
        if let v = data.sleepOnsetMinutes   { sleepOnsetMinutes = Double(min(v, 180)) }
        if let v = data.wakeAfterSleepOnset { wakeAfterSleepOnset = Double(min(v, 240)) }
        if let v = data.numberOfAwakenings  { numberOfAwakenings = Double(min(v, 20)) }

        healthSourceFields = data.sourceFields
    }

    private func save() {
        entry.bedTime = bedTime
        entry.lightsOutTime = adjustedLightsOut
        entry.finalWakeTime = adjustedFinalWake
        entry.outOfBedTime = adjustedOutOfBed
        entry.sleepOnsetMinutes = Int(sleepOnsetMinutes)
        entry.wakeAfterSleepOnset = Int(wakeAfterSleepOnset)
        entry.numberOfAwakenings = Int(numberOfAwakenings)
        entry.sleepQuality = sleepQuality
        entry.morningMood = morningMood
        entry.energyLevel = energyLevel
        entry.morningCompleted = true
        store.save(entry)
        dismiss()
    }
}

// MARK: - Health-aware field helpers

private struct HealthFieldLabel: View {
    let label: String
    let fromHealth: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
            if fromHealth {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.pink)
            }
        }
    }
}

private struct HealthLabeledPicker: View {
    let label: String
    @Binding var selection: Date
    let fromHealth: Bool

    var body: some View {
        if fromHealth {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(label)
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.pink)
                }
                DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        } else {
            DatePicker(label, selection: $selection, displayedComponents: .hourAndMinute)
        }
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
                                Text("\(i)").font(.caption2).foregroundStyle(i <= value ? Color.white : Color.secondary)
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

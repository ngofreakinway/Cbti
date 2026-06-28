import SwiftUI

struct EveningCheckInView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let entry: SleepEntry

    @State private var caffeineServings: Double
    @State private var alcoholServings: Double
    @State private var exerciseMinutes: Double
    @State private var napMinutes: Double
    @State private var painLevel: Double
    @State private var notes: String

    init(entry: SleepEntry) {
        self.entry = entry
        _caffeineServings = State(initialValue: Double(entry.caffeineServings))
        _alcoholServings = State(initialValue: Double(entry.alcoholServings))
        _exerciseMinutes = State(initialValue: Double(entry.exerciseMinutes))
        _napMinutes = State(initialValue: Double(entry.napMinutes))
        _painLevel = State(initialValue: Double(entry.painLevel))
        _notes = State(initialValue: entry.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Log today's behaviors that may affect tonight's sleep. Takes 1–2 minutes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Substances") {
                    SliderRow(
                        label: "Caffeine servings",
                        value: $caffeineServings,
                        range: 0...10,
                        step: 1,
                        unit: "cups/drinks",
                        color: .brown
                    )
                    SliderRow(
                        label: "Alcohol servings",
                        value: $alcoholServings,
                        range: 0...10,
                        step: 1,
                        unit: "drinks",
                        color: .purple
                    )
                }

                Section("Activity") {
                    SliderRow(
                        label: "Exercise",
                        value: $exerciseMinutes,
                        range: 0...120,
                        step: 10,
                        unit: "min",
                        color: .green
                    )
                    SliderRow(
                        label: "Nap",
                        value: $napMinutes,
                        range: 0...120,
                        step: 10,
                        unit: "min",
                        color: .orange
                    )
                    if napMinutes > 30 {
                        Text("Napping longer than 20–30 min can reduce sleep drive tonight.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Pain (0 = none)") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Pain level today")
                            Spacer()
                            Text(painLevel == 0 ? "None" : "\(Int(painLevel))/10")
                                .foregroundStyle(painLevel == 0 ? .green : .red)
                                .bold()
                        }
                        Slider(value: $painLevel, in: 0...10, step: 1)
                            .tint(.red)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .overlay(
                            Group {
                                if notes.isEmpty {
                                    Text("Anything notable today — stressors, mood, worries...")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .navigationTitle("Evening Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold()
                }
            }
        }
    }

    private func save() {
        entry.caffeineServings = Int(caffeineServings)
        entry.alcoholServings = Int(alcoholServings)
        entry.exerciseMinutes = Int(exerciseMinutes)
        entry.napMinutes = Int(napMinutes)
        entry.painLevel = Int(painLevel)
        entry.notes = notes
        entry.eveningCompleted = true
        store.save(entry)
        dismiss()
    }
}

private struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(value == 0 ? "None" : "\(Int(value)) \(unit)")
                    .foregroundStyle(value == 0 ? .secondary : color)
                    .bold()
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
        .padding(.vertical, 2)
    }
}

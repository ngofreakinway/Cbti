import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showResetConfirm = false

    private var profile: UserProfile? { store.profile }

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profile {
                    sleepWindowSection(profile)
                    conditionsSection(profile)
                    remindersSection(profile)
                    programSection(profile)
                }
                aboutSection
                resetSection
            }
            .navigationTitle("Settings")
            .alert("Reset Program?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { resetProgram() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your progress and completed modules will be cleared. Sleep diary entries are preserved.")
            }
        }
    }

    // MARK: - Sleep Window

    @ViewBuilder
    private func sleepWindowSection(_ profile: UserProfile) -> some View {
        Section {
            SleepWindowEditor(store: store, profile: profile)
        } header: {
            Label("Sleep Window", systemImage: "bed.double.fill")
        } footer: {
            Text("CBT-I prescribes a fixed wake time and a restricted time-in-bed window to consolidate sleep. Adjust weekly based on your Progress tab recommendation.")
        }
    }

    // MARK: - Conditions

    @ViewBuilder
    private func conditionsSection(_ profile: UserProfile) -> some View {
        Section {
            Toggle(isOn: Binding(
                get: { profile.hasDepression },
                set: { profile.hasDepression = $0; store.saveProfile() }
            )) {
                Label("Depression", systemImage: "cloud.rain.fill")
            }
            .tint(.blue)

            Toggle(isOn: Binding(
                get: { profile.hasAnxiety },
                set: { profile.hasAnxiety = $0; store.saveProfile() }
            )) {
                Label("Anxiety", systemImage: "waveform.path.ecg")
            }
            .tint(Color(red: 0.78, green: 0.58, blue: 0))

            Toggle(isOn: Binding(
                get: { profile.hasPain },
                set: { profile.hasPain = $0; store.saveProfile() }
            )) {
                Label("Chronic Pain", systemImage: "bolt.heart.fill")
            }
            .tint(.red)
        } header: {
            Label("My Conditions", systemImage: "heart.text.square.fill")
        } footer: {
            Text("Personalizes which modules and exercises appear in the Learn and Practice tabs.")
        }
    }

    // MARK: - Reminders

    @ViewBuilder
    private func remindersSection(_ profile: UserProfile) -> some View {
        Section {
            Toggle(isOn: Binding(
                get: { profile.morningReminderEnabled },
                set: { enabled in
                    profile.morningReminderEnabled = enabled
                    store.saveProfile()
                    if enabled {
                        NotificationManager.shared.scheduleMorningReminder(
                            hour: profile.morningReminderHour,
                            minute: profile.morningReminderMinute
                        )
                    } else {
                        NotificationManager.shared.cancelAll()
                        if profile.eveningReminderEnabled {
                            NotificationManager.shared.scheduleWindDownReminder(
                                bedHour: profile.prescribedBedTimeHour,
                                bedMinute: profile.prescribedBedTimeMinute,
                                minutesBefore: profile.windDownMinutesBefore
                            )
                        }
                    }
                }
            )) {
                Label("Morning Diary Reminder", systemImage: "sunrise.fill")
            }
            .tint(.orange)

            if profile.morningReminderEnabled {
                HStack {
                    Text("Reminder Time")
                    Spacer()
                    Text(String(format: "%02d:%02d", profile.morningReminderHour, profile.morningReminderMinute))
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: Binding(
                get: { profile.eveningReminderEnabled },
                set: { enabled in
                    profile.eveningReminderEnabled = enabled
                    store.saveProfile()
                    if enabled {
                        NotificationManager.shared.scheduleWindDownReminder(
                            bedHour: profile.prescribedBedTimeHour,
                            bedMinute: profile.prescribedBedTimeMinute,
                            minutesBefore: profile.windDownMinutesBefore
                        )
                    } else {
                        NotificationManager.shared.cancelAll()
                        if profile.morningReminderEnabled {
                            NotificationManager.shared.scheduleMorningReminder(
                                hour: profile.morningReminderHour,
                                minute: profile.morningReminderMinute
                            )
                        }
                    }
                }
            )) {
                Label("Wind-Down Reminder", systemImage: "moon.fill")
            }
            .tint(.indigo)

            if profile.eveningReminderEnabled {
                HStack {
                    Text("Before Bedtime")
                    Spacer()
                    Text("\(profile.windDownMinutesBefore) minutes before")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Reminders", systemImage: "bell.fill")
        } footer: {
            Text("Reminders help you log your sleep diary consistently — the most important habit in this program.")
        }
    }

    // MARK: - Program Info

    @ViewBuilder
    private func programSection(_ profile: UserProfile) -> some View {
        Section {
            HStack {
                Text("Program Start")
                Spacer()
                Text(profile.programStartDate, style: .date)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Current Day")
                Spacer()
                Text("Day \(store.programDayNumber)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Current Week")
                Spacer()
                Text("Week \(profile.currentWeek) of 8")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Modules Completed")
                Spacer()
                Text("\(profile.completedModuleIDs.count)")
                    .foregroundStyle(.secondary)
            }
            if store.currentStreak > 0 {
                HStack {
                    Text("Current Streak")
                    Spacer()
                    Label("\(store.currentStreak) days", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Label("Program", systemImage: "calendar.badge.clock")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0").foregroundStyle(.secondary)
            }
            HStack {
                Text("Based on")
                Spacer()
                Text("Carney & Manber (CBT-I)")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Treatment")
                Spacer()
                Text("CBT for Insomnia")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("About", systemImage: "info.circle.fill")
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset Program Progress", systemImage: "arrow.counterclockwise")
            }
        } footer: {
            Text("Clears completed modules, exercises, and resets your program to Day 1. Sleep diary entries are not affected.")
        }
    }

    private func resetProgram() {
        guard let profile = profile else { return }
        profile.completedModuleIDs = []
        profile.completedExerciseIDs = []
        profile.currentWeek = 1
        profile.programStartDate = Date()
        store.saveProfile()
    }
}

// MARK: - Sleep Window Editor (inline form rows)

private struct SleepWindowEditor: View {
    let store: AppStore
    let profile: UserProfile

    @State private var wakeTime: Date
    @State private var tibHours: Double
    @State private var isDirty = false

    init(store: AppStore, profile: UserProfile) {
        self.store = store
        self.profile = profile
        let wake = Calendar.current.date(
            bySettingHour: profile.prescribedWakeTimeHour,
            minute: profile.prescribedWakeTimeMinute,
            second: 0, of: Date()
        ) ?? Date()
        _wakeTime = State(initialValue: wake)
        _tibHours = State(initialValue: max(5.0, profile.prescribedTimeInBedHours))
    }

    private var computedBedtime: (hour: Int, minute: Int) {
        let cal = Calendar.current
        return SleepCalculator.bedtime(
            wakeHour: cal.component(.hour, from: wakeTime),
            wakeMinute: cal.component(.minute, from: wakeTime),
            tibMinutes: Int(tibHours * 60)
        )
    }

    private func timeString(_ h: Int, _ m: Int) -> String {
        let isPM = h >= 12; let dh = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", dh, m, isPM ? "PM" : "AM")
    }

    var body: some View {
        DatePicker("Fixed Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
            .onChange(of: wakeTime) { isDirty = true }

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Time in Bed")
                Spacer()
                Text(String(format: "%.1f hours", tibHours))
                    .foregroundStyle(isDirty ? Color.indigo : Color.secondary)
            }
            Slider(value: $tibHours, in: 5...10, step: 0.5)
                .tint(.indigo)
                .onChange(of: tibHours) { isDirty = true }
            Text("Minimum 5 hours. Increase only after 85%+ sleep efficiency.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)

        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Prescribed Bedtime")
                    .font(.caption).foregroundStyle(.secondary)
                Text(timeString(computedBedtime.hour, computedBedtime.minute))
                    .font(.title3.bold()).foregroundStyle(.indigo)
            }
            Spacer()
            if isDirty {
                Button("Save") {
                    let cal = Calendar.current
                    store.updateSleepWindow(
                        wakeHour: cal.component(.hour, from: wakeTime),
                        wakeMinute: cal.component(.minute, from: wakeTime),
                        tibMinutes: Int(tibHours * 60)
                    )
                    isDirty = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
        }
        .padding(.vertical, 4)
    }
}

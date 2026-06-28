import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch page {
            case 0: WelcomePage(onNext: { page = 1 })
            case 1: ConditionPage(onNext: { page = 2 })
            case 2: SleepWindowSetupPage(onFinish: finishOnboarding)
            default: EmptyView()
            }
        }
        .animation(.easeInOut, value: page)
    }

    private func finishOnboarding() {
        store.profile?.onboardingCompleted = true
        store.saveProfile()
        Task { await NotificationManager.shared.requestAuthorization() }
    }
}

// MARK: - Welcome

private struct WelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundStyle(.indigo)

            VStack(spacing: 12) {
                Text("Quiet Your Mind")
                    .font(.largeTitle.bold())
                Text("Get to Sleep")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Text("An interactive companion to the evidence-based CBT-I workbook for insomnia, depression, and anxiety.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Label("Based on CBT-I — the gold-standard treatment for chronic insomnia", systemImage: "checkmark.circle.fill")
                Label("Daily sleep diary with progress tracking", systemImage: "checkmark.circle.fill")
                Label("Guided exercises for relaxation and worry", systemImage: "checkmark.circle.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.indigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Condition Selection

private struct ConditionPage: View {
    @EnvironmentObject var store: AppStore
    let onNext: () -> Void

    @State private var hasDepression = false
    @State private var hasAnxiety = false
    @State private var hasPain = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Tell us about yourself")
                    .font(.title.bold())
                Text("This personalizes your program. Select all that apply.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 16) {
                ConditionCard(
                    icon: "cloud.rain.fill",
                    title: "Depression",
                    description: "Low mood, low energy, or loss of interest that affects your daily life",
                    color: .blue,
                    isSelected: $hasDepression
                )
                ConditionCard(
                    icon: "waveform.path.ecg",
                    title: "Anxiety",
                    description: "Worry, racing thoughts, or tension that is hard to control",
                    color: .yellow,
                    isSelected: $hasAnxiety
                )
                ConditionCard(
                    icon: "bolt.heart.fill",
                    title: "Chronic Pain",
                    description: "Ongoing physical pain that disrupts your sleep or daily activity",
                    color: .red,
                    isSelected: $hasPain
                )
            }
            .padding(.horizontal, 20)

            Spacer()

            Text("You can update this later in Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: save) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.indigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func save() {
        let profile = store.profile ?? store.createDefaultProfile()
        profile.hasDepression = hasDepression
        profile.hasAnxiety = hasAnxiety
        profile.hasPain = hasPain
        store.saveProfile()
        onNext()
    }
}

private struct ConditionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: { isSelected.toggle() }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? color : color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(description).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.indigo : Color.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.indigo : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sleep Window Setup

private struct SleepWindowSetupPage: View {
    @EnvironmentObject var store: AppStore
    let onFinish: () -> Void

    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var estimatedSleepHours: Double = 6.0

    private var bedtime: Date {
        let tibMinutes = Int(estimatedSleepHours * 60)
        let cal = Calendar.current
        let wakeH = cal.component(.hour, from: wakeTime)
        let wakeM = cal.component(.minute, from: wakeTime)
        let (h, m) = SleepCalculator.bedtime(wakeHour: wakeH, wakeMinute: wakeM, tibMinutes: tibMinutes)
        return cal.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                VStack(spacing: 8) {
                    Text("Set Your Sleep Window")
                        .font(.title.bold())
                    Text("We'll use this as your starting point. You can adjust it as your sleep improves.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Fixed Wake Time", systemImage: "sunrise.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("This is the most important number. Keep it consistent every day, even after a bad night.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Estimated Sleep per Night", systemImage: "moon.fill")
                        .font(.headline)
                        .foregroundStyle(.indigo)
                    Text("How many hours do you actually sleep (not time in bed)? Be honest — this is your baseline.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("\(estimatedSleepHours, specifier: "%.1f") hours")
                            .font(.title2.bold())
                            .foregroundStyle(.indigo)
                        Spacer()
                        Text("minimum 5h")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $estimatedSleepHours, in: 5...10, step: 0.5)
                        .tint(.indigo)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Prescribed Bedtime")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(bedtime, style: .time)
                                .font(.title.bold())
                                .foregroundStyle(.indigo)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Fixed Wake Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(wakeTime, style: .time)
                                .font(.title.bold())
                                .foregroundStyle(.orange)
                        }
                    }
                    Divider()
                    Text("Start by going to bed no earlier than \(bedtime, style: .time). As your sleep efficiency improves, we'll move this earlier.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                Button(action: save) {
                    Text("Start My Program")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.indigo)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func save() {
        let profile = store.profile ?? store.createDefaultProfile()
        let cal = Calendar.current
        profile.prescribedWakeTimeHour = cal.component(.hour, from: wakeTime)
        profile.prescribedWakeTimeMinute = cal.component(.minute, from: wakeTime)
        let (h, m) = SleepCalculator.bedtime(
            wakeHour: profile.prescribedWakeTimeHour,
            wakeMinute: profile.prescribedWakeTimeMinute,
            tibMinutes: Int(estimatedSleepHours * 60)
        )
        profile.prescribedBedTimeHour = h
        profile.prescribedBedTimeMinute = m
        // Schedule morning reminder 30 min after wake time, handling hour rollover
        let wakeTotal = profile.prescribedWakeTimeHour * 60 + profile.prescribedWakeTimeMinute + 30
        profile.morningReminderHour = (wakeTotal / 60) % 24
        profile.morningReminderMinute = wakeTotal % 60
        store.saveProfile()

        if profile.morningReminderEnabled {
            NotificationManager.shared.scheduleMorningReminder(
                hour: profile.morningReminderHour,
                minute: profile.morningReminderMinute
            )
        }
        if profile.eveningReminderEnabled {
            NotificationManager.shared.scheduleWindDownReminder(
                bedHour: h, bedMinute: m,
                minutesBefore: profile.windDownMinutesBefore
            )
        }

        onFinish()
    }
}

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: AppStore
    @State private var showMorningCheckIn = false
    @State private var showEveningCheckIn = false

    private var profile: UserProfile? { store.profile }
    private var todayEntry: SleepEntry? { store.entryForToday() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Prescribed sleep window banner
                    if let profile {
                        SleepWindowBanner(profile: profile)
                    }

                    // Check-in cards
                    VStack(spacing: 12) {
                        CheckInCard(
                            title: "Morning Log",
                            subtitle: "How did you sleep last night?",
                            icon: "sunrise.fill",
                            iconColor: .orange,
                            isCompleted: todayEntry?.morningCompleted ?? false,
                            action: { showMorningCheckIn = true }
                        )
                        CheckInCard(
                            title: "Evening Check-In",
                            subtitle: "Factors that may affect tonight",
                            icon: "moon.fill",
                            iconColor: .indigo,
                            isCompleted: todayEntry?.eveningCompleted ?? false,
                            action: { showEveningCheckIn = true }
                        )
                    }
                    .padding(.horizontal)

                    // Today's stats (if morning done)
                    if let entry = todayEntry, entry.morningCompleted {
                        TodayStatsCard(entry: entry)
                            .padding(.horizontal)
                    }

                    // Sleep window rules reminder
                    StimulusControlReminder()
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showMorningCheckIn) {
                MorningCheckInView(entry: getOrCreateEntry())
                    .environmentObject(store)
            }
            .sheet(isPresented: $showEveningCheckIn) {
                EveningCheckInView(entry: getOrCreateEntry())
                    .environmentObject(store)
            }
        }
    }

    private func getOrCreateEntry() -> SleepEntry {
        store.createEntryForToday()
    }
}

// MARK: - Sleep Window Banner

private struct SleepWindowBanner: View {
    let profile: UserProfile

    private var bedtimeText: String {
        String(format: "%02d:%02d", profile.prescribedBedTimeHour, profile.prescribedBedTimeMinute)
    }
    private var wakeText: String {
        String(format: "%02d:%02d", profile.prescribedWakeTimeHour, profile.prescribedWakeTimeMinute)
    }
    private var tibHours: String {
        String(format: "%.1fh window", profile.prescribedTimeInBedHours)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.indigo)
                Text("Bedtime")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(bedtimeText)
                    .font(.title2.bold())
                    .foregroundStyle(.indigo)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                Text(tibHours)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Image(systemName: "sunrise.fill")
                    .foregroundStyle(.orange)
                Text("Wake")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(wakeText)
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Check-In Card

private struct CheckInCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isCompleted ? .white : iconColor)
                    .frame(width: 48, height: 48)
                    .background(isCompleted ? iconColor : iconColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Stats

private struct TodayStatsCard: View {
    let entry: SleepEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Night")
                .font(.headline)

            HStack(spacing: 0) {
                StatItem(label: "Sleep Time", value: SleepCalculator.formatMinutes(entry.totalSleepTime), color: .indigo)
                Divider().frame(height: 40)
                StatItem(label: "Efficiency", value: String(format: "%.0f%%", entry.sleepEfficiency), color: efficiencyColor)
                Divider().frame(height: 40)
                StatItem(label: "Time Awake", value: SleepCalculator.formatMinutes(entry.wakeAfterSleepOnset), color: .orange)
            }

            EfficiencyBar(efficiency: entry.sleepEfficiency)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var efficiencyColor: Color {
        entry.sleepEfficiency >= 90 ? .green : entry.sleepEfficiency >= 85 ? .yellow : .red
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EfficiencyBar: View {
    let efficiency: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(efficiency / 100, 1))
                }
            }
            .frame(height: 8)

            HStack {
                Text("SE Goal: 85%").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", efficiency)).font(.caption2).foregroundStyle(barColor)
            }
        }
    }

    private var barColor: Color {
        efficiency >= 90 ? .green : efficiency >= 85 ? .yellow : .red
    }
}

// MARK: - Stimulus Control Reminder

private struct StimulusControlReminder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tonight's Rules", systemImage: "checklist")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                RuleRow(text: "Go to bed only when sleepy, not just tired")
                RuleRow(text: "Bed is for sleep only — no screens in bed")
                RuleRow(text: "If awake 20+ min, get up and do something calm")
                RuleRow(text: "Keep your wake time fixed regardless of sleep")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RuleRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "moon.fill")
                .font(.caption)
                .foregroundStyle(.indigo)
                .padding(.top, 2)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}

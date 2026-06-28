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
                VStack(spacing: 16) {
                    HeroCard(dayNumber: store.programDayNumber, streak: store.currentStreak, week: profile?.currentWeek ?? 1)

                    if let profile { SleepWindowBanner(profile: profile) }

                    VStack(spacing: 12) {
                        CheckInCard(
                            title: "Morning Log",
                            subtitle: "How did you sleep last night?",
                            icon: "sunrise.fill",
                            iconColor: .orange,
                            isCompleted: todayEntry?.morningCompleted ?? false
                        ) { showMorningCheckIn = true }

                        CheckInCard(
                            title: "Evening Check-In",
                            subtitle: "Factors that may affect tonight",
                            icon: "moon.stars.fill",
                            iconColor: .indigo,
                            isCompleted: todayEntry?.eveningCompleted ?? false
                        ) { showEveningCheckIn = true }
                    }

                    if let entry = todayEntry, entry.morningCompleted {
                        TodayStatsCard(entry: entry)
                    }

                    StimulusControlReminder()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Today")
            .sheet(isPresented: $showMorningCheckIn) {
                MorningCheckInView(entry: store.createEntryForToday())
                    .environmentObject(store)
            }
            .sheet(isPresented: $showEveningCheckIn) {
                EveningCheckInView(entry: store.createEntryForToday())
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - Hero Card

private struct HeroCard: View {
    let dayNumber: Int
    let streak: Int
    let week: Int

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.24, green: 0.18, blue: 0.60), Color(red: 0.44, green: 0.28, blue: 0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative background icon
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(.white.opacity(0.07))
                        .offset(x: 20, y: 0)
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(greeting)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.70))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Day")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.70))
                    Text("\(dayNumber)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 10) {
                    Label("Week \(week) of 8", systemImage: "calendar")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.70))

                    if streak > 1 {
                        Label("\(streak)-day streak", systemImage: "flame.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.orange)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.18))
                            .clipShape(Capsule())
                    } else if streak == 1 {
                        Label("First log!", systemImage: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.indigo.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Sleep Window Banner

private struct SleepWindowBanner: View {
    let profile: UserProfile

    private func timeString(hour: Int, minute: Int) -> String {
        let isPM = hour >= 12
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", h, minute, isPM ? "PM" : "AM")
    }

    private var tibText: String {
        let h = profile.prescribedTimeInBedHours
        let hrs = Int(h)
        let mins = Int((h - Double(hrs)) * 60)
        return mins == 0 ? "\(hrs)h window" : "\(hrs)h \(mins)m window"
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 5) {
                Image(systemName: "moon.fill")
                    .font(.subheadline)
                    .foregroundStyle(.indigo.opacity(0.8))
                Text("Bedtime")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(timeString(hour: profile.prescribedBedTimeHour, minute: profile.prescribedBedTimeMinute))
                    .font(.title3.bold())
                    .foregroundStyle(.indigo)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(Color(.systemGray3))
                Text(tibText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 5) {
                Image(systemName: "sunrise.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange.opacity(0.9))
                Text("Wake")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(timeString(hour: profile.prescribedWakeTimeHour, minute: profile.prescribedWakeTimeMinute))
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
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
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isCompleted ? iconColor : iconColor.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: isCompleted ? "checkmark" : icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isCompleted ? .white : iconColor)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(isCompleted ? "Completed ✓" : subtitle)
                        .font(.caption)
                        .foregroundStyle(isCompleted ? .green : .secondary)
                }

                Spacer()

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                    .font(isCompleted ? .title3 : .body)
                    .foregroundStyle(isCompleted ? .green : Color(.systemGray3))
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Stats Card

private struct TodayStatsCard: View {
    let entry: SleepEntry

    private var se: Double { entry.sleepEfficiency }
    private var seColor: Color { se >= 90 ? .green : se >= 85 ? Color(red: 0.75, green: 0.55, blue: 0) : .red }
    private var seLabel: String { se >= 90 ? "Excellent" : se >= 85 ? "On target" : "Below goal" }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Last Night", systemImage: "moon.zzz.fill")
                .font(.headline)

            HStack(spacing: 0) {
                StatPill(icon: "moon.fill", label: "Sleep Time",
                         value: SleepCalculator.formatMinutes(entry.totalSleepTime), color: .indigo)
                Divider().frame(height: 48)
                StatPill(icon: "percent", label: "Efficiency",
                         value: String(format: "%.0f%%", se), color: seColor)
                Divider().frame(height: 48)
                StatPill(icon: "clock.fill", label: "Awake",
                         value: SleepCalculator.formatMinutes(entry.sleepOnsetMinutes + entry.wakeAfterSleepOnset),
                         color: .orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [seColor.opacity(0.65), seColor],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * min(se / 100, 1))
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("SE goal: 85%").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text(seLabel).font(.caption2.weight(.semibold)).foregroundStyle(seColor)
                }
            }

            if entry.sleepQuality > 0 {
                HStack(spacing: 4) {
                    Text("Quality:")
                        .font(.caption2).foregroundStyle(.secondary)
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= entry.sleepQuality ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(i <= entry.sleepQuality ? Color.orange : Color(.systemGray4))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundStyle(color.opacity(0.8))
            Text(value).font(.headline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stimulus Control Reminder

private struct StimulusControlReminder: View {
    private let rules: [(String, String)] = [
        ("bed.double.fill", "Only go to bed when genuinely sleepy — not just tired"),
        ("iphone.slash", "Bed is for sleep only — no screens, reading, or worrying in bed"),
        ("figure.walk", "If awake 20+ minutes, get up until sleepy again"),
        ("alarm.fill", "Keep your wake time fixed, even after a bad night"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tonight's Rules", systemImage: "checklist")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rules, id: \.0) { icon, text in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(.indigo)
                            .frame(width: 16, alignment: .center)
                            .padding(.top, 2)
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

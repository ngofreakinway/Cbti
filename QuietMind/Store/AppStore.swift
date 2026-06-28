import Foundation
import SwiftData
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    private var modelContext: ModelContext?

    @Published var profile: UserProfile?
    @Published var sleepEntries: [SleepEntry] = []
    @Published var isReady = false

    func setup(context: ModelContext) {
        guard modelContext == nil else { return }
        self.modelContext = context
        loadProfile()
        loadEntries()
        isReady = true
    }

    // MARK: - Profile

    func loadProfile() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<UserProfile>()
        profile = try? ctx.fetch(descriptor).first
    }

    func saveProfile() {
        try? modelContext?.save()
        objectWillChange.send()
    }

    @discardableResult
    func createDefaultProfile() -> UserProfile {
        guard let ctx = modelContext else { fatalError("Store not set up") }
        let p = UserProfile()
        ctx.insert(p)
        try? ctx.save()
        self.profile = p
        return p
    }

    // MARK: - Sleep Entries

    func loadEntries() {
        guard let ctx = modelContext else { return }
        var descriptor = FetchDescriptor<SleepEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 90
        sleepEntries = (try? ctx.fetch(descriptor)) ?? []
    }

    func entryForToday() -> SleepEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return sleepEntries.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    @discardableResult
    func createEntryForToday() -> SleepEntry {
        if let existing = entryForToday() { return existing }
        guard let ctx = modelContext else { fatalError("Store not set up") }
        let entry = SleepEntry(date: Date())
        ctx.insert(entry)
        try? ctx.save()
        loadEntries()
        return entry
    }

    func save(_ entry: SleepEntry) {
        try? modelContext?.save()
        loadEntries()
    }

    // MARK: - Computed metrics (last 7 days)

    var last7Entries: [SleepEntry] {
        Array(sleepEntries.prefix(7).reversed())
    }

    var averageSleepEfficiency7d: Double {
        let completed = last7Entries.filter { $0.morningCompleted && $0.timeInBed > 0 }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0) { $0 + $1.sleepEfficiency } / Double(completed.count)
    }

    var averageTST7d: Double {
        let completed = last7Entries.filter { $0.morningCompleted }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0.0) { $0 + Double($1.totalSleepTime) } / Double(completed.count)
    }

    func recommendedSleepWindowMinutes() -> Int {
        let avgTST = averageTST7d
        guard avgTST > 0 else { return 7 * 60 }
        return max(5 * 60, Int(avgTST))
    }

    // MARK: - Streak & program day

    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        for _ in 0..<90 {
            let hasEntry = sleepEntries.contains {
                cal.isDate($0.date, inSameDayAs: checkDate) && $0.morningCompleted
            }
            if hasEntry {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    var programDayNumber: Int {
        guard let profile = profile else { return 1 }
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: profile.programStartDate),
            to: cal.startOfDay(for: Date())
        ).day ?? 0
        return max(1, days + 1)
    }

    // MARK: - Sleep window management

    func applyWindowAdjustment() {
        guard let profile = profile else { return }
        let currentTIB = Int(profile.prescribedTimeInBedHours * 60)
        let result = SleepCalculator.sleepWindowAdjustment(
            sleepEfficiency: averageSleepEfficiency7d,
            currentTIBMinutes: currentTIB
        )
        let newTIB = max(5 * 60, currentTIB + result.adjustment)
        let (h, m) = SleepCalculator.bedtime(
            wakeHour: profile.prescribedWakeTimeHour,
            wakeMinute: profile.prescribedWakeTimeMinute,
            tibMinutes: newTIB
        )
        profile.prescribedBedTimeHour = h
        profile.prescribedBedTimeMinute = m
        saveProfile()
        if profile.eveningReminderEnabled {
            NotificationManager.shared.scheduleWindDownReminder(
                bedHour: h, bedMinute: m,
                minutesBefore: profile.windDownMinutesBefore
            )
        }
    }

    func updateSleepWindow(wakeHour: Int, wakeMinute: Int, tibMinutes: Int) {
        guard let profile = profile else { return }
        profile.prescribedWakeTimeHour = wakeHour
        profile.prescribedWakeTimeMinute = wakeMinute
        let (h, m) = SleepCalculator.bedtime(
            wakeHour: wakeHour,
            wakeMinute: wakeMinute,
            tibMinutes: tibMinutes
        )
        profile.prescribedBedTimeHour = h
        profile.prescribedBedTimeMinute = m
        saveProfile()
        if profile.morningReminderEnabled {
            let wakeTotal = wakeHour * 60 + wakeMinute + 30
            NotificationManager.shared.scheduleMorningReminder(
                hour: (wakeTotal / 60) % 24,
                minute: wakeTotal % 60
            )
        }
        if profile.eveningReminderEnabled {
            NotificationManager.shared.scheduleWindDownReminder(
                bedHour: h, bedMinute: m,
                minutesBefore: profile.windDownMinutesBefore
            )
        }
    }
}

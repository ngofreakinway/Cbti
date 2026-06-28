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
}

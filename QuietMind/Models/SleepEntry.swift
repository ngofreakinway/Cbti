import Foundation
import SwiftData

@Model
final class SleepEntry {
    var id: UUID
    var date: Date                  // The night this entry covers (normalized to midnight)

    // Time in bed window
    var bedTime: Date               // When they got into bed
    var lightsOutTime: Date         // When they turned off lights/tried to sleep
    var finalWakeTime: Date         // Last wake of the night
    var outOfBedTime: Date          // When they got out of bed

    // Sleep quality
    var sleepOnsetMinutes: Int      // How long it took to fall asleep (SOL)
    var wakeAfterSleepOnset: Int    // Total minutes awake during the night (WASO)
    var numberOfAwakenings: Int

    // Subjective ratings (1–5)
    var sleepQuality: Int
    var morningMood: Int
    var energyLevel: Int

    // Factors
    var napMinutes: Int
    var caffeineServings: Int
    var alcoholServings: Int
    var exerciseMinutes: Int
    var painLevel: Int              // 0 = none, 1–10

    var notes: String

    // Completion flags
    var morningCompleted: Bool
    var eveningCompleted: Bool

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)

        let now = Date()
        let cal = Calendar.current
        // Default bed/lights-out to yesterday 11 PM so the pickers open with a sensible value
        // and midnight-crossing math produces a positive TIB from the start.
        let yesterday = cal.date(byAdding: .day, value: -1, to: now) ?? now
        let defaultBed = cal.date(bySettingHour: 23, minute: 0, second: 0, of: yesterday) ?? now
        self.bedTime = defaultBed
        self.lightsOutTime = defaultBed
        self.finalWakeTime = now
        self.outOfBedTime = now

        self.sleepOnsetMinutes = 0
        self.wakeAfterSleepOnset = 0
        self.numberOfAwakenings = 0

        self.sleepQuality = 3
        self.morningMood = 3
        self.energyLevel = 3

        self.napMinutes = 0
        self.caffeineServings = 0
        self.alcoholServings = 0
        self.exerciseMinutes = 0
        self.painLevel = 0

        self.notes = ""
        self.morningCompleted = false
        self.eveningCompleted = false
    }

    // MARK: - Derived metrics

    /// Time In Bed in minutes
    var timeInBed: Int {
        max(0, Int(outOfBedTime.timeIntervalSince(bedTime) / 60))
    }

    /// Minutes lying awake in bed after the final awakening (before getting up)
    var awakeAfterFinalWake: Int {
        max(0, Int(outOfBedTime.timeIntervalSince(finalWakeTime) / 60))
    }

    /// Total Sleep Time in minutes
    /// TST = TIB − SOL − WASO − (outOfBed − finalWake)
    var totalSleepTime: Int {
        let awake = sleepOnsetMinutes + wakeAfterSleepOnset + awakeAfterFinalWake
        return max(0, timeInBed - awake)
    }

    /// Sleep Efficiency as percentage (0–100)
    var sleepEfficiency: Double {
        guard timeInBed > 0 else { return 0 }
        return Double(totalSleepTime) / Double(timeInBed) * 100
    }
}

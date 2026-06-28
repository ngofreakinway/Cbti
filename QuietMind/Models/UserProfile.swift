import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID

    // Onboarding
    var onboardingCompleted: Bool
    var hasDepression: Bool
    var hasAnxiety: Bool
    var hasPain: Bool

    // Prescribed sleep window (set by sleep restriction protocol)
    var prescribedBedTimeHour: Int      // 0–23
    var prescribedBedTimeMinute: Int
    var prescribedWakeTimeHour: Int
    var prescribedWakeTimeMinute: Int

    // Program progress
    var programStartDate: Date
    var currentWeek: Int
    var completedModuleIDs: [String]
    var completedExerciseIDs: [String]

    // Notification preferences
    var morningReminderEnabled: Bool
    var morningReminderHour: Int
    var morningReminderMinute: Int
    var eveningReminderEnabled: Bool    // winds-down 30 min before prescribed bed
    var windDownMinutesBefore: Int

    init() {
        self.id = UUID()
        self.onboardingCompleted = false
        self.hasDepression = false
        self.hasAnxiety = false
        self.hasPain = false

        // Default: 11 PM bed, 7 AM wake
        self.prescribedBedTimeHour = 23
        self.prescribedBedTimeMinute = 0
        self.prescribedWakeTimeHour = 7
        self.prescribedWakeTimeMinute = 0

        self.programStartDate = Date()
        self.currentWeek = 1
        self.completedModuleIDs = []
        self.completedExerciseIDs = []

        self.morningReminderEnabled = true
        self.morningReminderHour = 7
        self.morningReminderMinute = 30
        self.eveningReminderEnabled = true
        self.windDownMinutesBefore = 30
    }

    var prescribedTimeInBedHours: Double {
        let bedMinutes = prescribedBedTimeHour * 60 + prescribedBedTimeMinute
        var wakeMinutes = prescribedWakeTimeHour * 60 + prescribedWakeTimeMinute
        if wakeMinutes <= bedMinutes { wakeMinutes += 24 * 60 }
        return Double(wakeMinutes - bedMinutes) / 60.0
    }
}

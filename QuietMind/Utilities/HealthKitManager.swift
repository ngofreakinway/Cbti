import Foundation
import HealthKit

struct LastNightSleep {
    var bedTime: Date?
    var lightsOutTime: Date?
    var sleepOnsetMinutes: Int?
    var wakeAfterSleepOnset: Int?
    var numberOfAwakenings: Int?
    var finalWakeTime: Date?
    var outOfBedTime: Date?
    // Which fields were sourced from HealthKit
    var sourceFields: Set<String> = []
}

@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
            return true
        } catch {
            return false
        }
    }

    func fetchLastNight() async -> LastNightSleep {
        guard isAvailable,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return LastNightSleep()
        }

        // Query the 24 hours ending at noon today to capture a full night
        let now = Date()
        let cal = Calendar.current
        let noonToday = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let noonYesterday = cal.date(byAdding: .day, value: -1, to: noonToday) ?? now

        let predicate = HKQuery.predicateForSamples(withStart: noonYesterday, end: noonToday, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        return process(samples: samples)
    }

    private func process(samples: [HKCategorySample]) -> LastNightSleep {
        guard !samples.isEmpty else { return LastNightSleep() }

        let inBedSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        let asleepSamples = samples.filter { asleepValues.contains($0.value) }
        let awakeSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.awake.rawValue }

        var result = LastNightSleep()

        // Bed time — start of first inBed sample
        if let firstInBed = inBedSamples.first {
            result.bedTime = firstInBed.startDate
            result.lightsOutTime = firstInBed.startDate // HealthKit can't distinguish
            result.sourceFields.insert("bedTime")
            result.sourceFields.insert("lightsOutTime")
        }

        // Out of bed — end of last inBed sample
        if let lastInBed = inBedSamples.last {
            result.outOfBedTime = lastInBed.endDate
            result.sourceFields.insert("outOfBedTime")
        }

        // Sleep onset — gap between first inBed start and first asleep start
        if let firstInBed = inBedSamples.first, let firstAsleep = asleepSamples.first {
            let onset = max(0, Int(firstAsleep.startDate.timeIntervalSince(firstInBed.startDate) / 60))
            result.sleepOnsetMinutes = onset
            result.sourceFields.insert("sleepOnsetMinutes")
        }

        // Final wake time — start of last awake sample, or end of last asleep sample
        if let lastAwake = awakeSamples.last {
            result.finalWakeTime = lastAwake.startDate
            result.sourceFields.insert("finalWakeTime")
        } else if let lastAsleep = asleepSamples.last {
            result.finalWakeTime = lastAsleep.endDate
            result.sourceFields.insert("finalWakeTime")
        }

        // Wake after sleep onset — total duration of awake samples after first sleep starts
        if let firstAsleep = asleepSamples.first {
            let waso = awakeSamples
                .filter { $0.startDate >= firstAsleep.startDate }
                .reduce(0) { $0 + Int($1.endDate.timeIntervalSince($1.startDate) / 60) }
            result.wakeAfterSleepOnset = waso
            result.sourceFields.insert("wakeAfterSleepOnset")

            let awakenings = awakeSamples.filter { $0.startDate >= firstAsleep.startDate }.count
            result.numberOfAwakenings = awakenings
            result.sourceFields.insert("numberOfAwakenings")
        }

        return result
    }
}

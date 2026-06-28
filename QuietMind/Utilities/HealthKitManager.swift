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
    var sourceFields: Set<String> = []
}

// Not @MainActor — HealthKit uses its own background queues for queries.
final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // Returns true if the authorization sheet was presented (or already answered).
    // HealthKit never tells us whether permission was actually granted — it just
    // returns empty results if it wasn't.
    func requestAuthorization() async throws {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HKError(.errorInvalidArgument)
        }
        try await store.requestAuthorization(toShare: [], read: [sleepType])
    }

    func fetchLastNight() async -> LastNightSleep {
        guard isAvailable,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return LastNightSleep()
        }

        let now = Date()
        let cal = Calendar.current
        // Window: yesterday noon → today noon, captures a full night for any bed/wake time
        let noonToday = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
        let noonYesterday = cal.date(byAdding: .day, value: -1, to: noonToday) ?? now

        let predicate = HKQuery.predicateForSamples(
            withStart: noonYesterday, end: noonToday, options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples: [HKCategorySample] = await withCheckedContinuation { cont in
            let q = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, results, _ in
                cont.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(q)
        }

        return process(samples: samples)
    }

    private func process(samples: [HKCategorySample]) -> LastNightSleep {
        guard !samples.isEmpty else { return LastNightSleep() }

        let inBedSamples = samples.filter {
            $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue
        }
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]
        let asleepSamples = samples.filter { asleepValues.contains($0.value) }
        let awakeSamples  = samples.filter {
            $0.value == HKCategoryValueSleepAnalysis.awake.rawValue
        }

        var result = LastNightSleep()

        // Prefer inBed samples; fall back to first asleep sample for bed time
        if let firstInBed = inBedSamples.first ?? asleepSamples.first {
            result.bedTime = firstInBed.startDate
            result.lightsOutTime = firstInBed.startDate
            result.sourceFields.insert("bedTime")
            result.sourceFields.insert("lightsOutTime")
        }

        if let lastInBed = inBedSamples.last ?? asleepSamples.last {
            result.outOfBedTime = lastInBed.endDate
            result.sourceFields.insert("outOfBedTime")
        }

        if let firstBed = result.bedTime, let firstAsleep = asleepSamples.first {
            let onset = max(0, Int(firstAsleep.startDate.timeIntervalSince(firstBed) / 60))
            result.sleepOnsetMinutes = onset
            result.sourceFields.insert("sleepOnsetMinutes")
        }

        if let lastAwake = awakeSamples.last {
            result.finalWakeTime = lastAwake.startDate
            result.sourceFields.insert("finalWakeTime")
        } else if let lastAsleep = asleepSamples.last {
            result.finalWakeTime = lastAsleep.endDate
            result.sourceFields.insert("finalWakeTime")
        }

        if let firstAsleep = asleepSamples.first {
            let waso = awakeSamples
                .filter { $0.startDate >= firstAsleep.startDate }
                .reduce(0) { $0 + Int($1.endDate.timeIntervalSince($1.startDate) / 60) }
            result.wakeAfterSleepOnset = waso
            result.sourceFields.insert("wakeAfterSleepOnset")

            result.numberOfAwakenings = awakeSamples
                .filter { $0.startDate >= firstAsleep.startDate }.count
            result.sourceFields.insert("numberOfAwakenings")
        }

        return result
    }
}

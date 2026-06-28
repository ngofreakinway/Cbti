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
    // Computed directly from asleep sample durations — more accurate than TIB - SOL - WASO
    var totalSleepMinutes: Int?
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

        // --- Bed time: start of first inBed, or first asleep if no inBed data ---
        if let first = inBedSamples.first ?? asleepSamples.first {
            result.bedTime = first.startDate
            result.lightsOutTime = first.startDate
            result.sourceFields.insert("bedTime")
            result.sourceFields.insert("lightsOutTime")
        }

        // --- Out of bed: end of last inBed, or end of last asleep ---
        if let last = inBedSamples.last ?? asleepSamples.last {
            result.outOfBedTime = last.endDate
            result.sourceFields.insert("outOfBedTime")
        }

        // --- Sleep onset: gap between first bed-entry and first sleep ---
        // Only meaningful when we have a real inBed sample (not the asleep fallback)
        if let firstBed = inBedSamples.first, let firstAsleep = asleepSamples.first,
           firstAsleep.startDate > firstBed.startDate {
            result.sleepOnsetMinutes = Int(firstAsleep.startDate.timeIntervalSince(firstBed.startDate) / 60)
            result.sourceFields.insert("sleepOnsetMinutes")
        } else if inBedSamples.isEmpty {
            result.sleepOnsetMinutes = 0
            result.sourceFields.insert("sleepOnsetMinutes")
        }

        // --- Total sleep: sum of all asleep-stage sample durations ---
        // More accurate than TIB - SOL - WASO because HealthKit's awake samples
        // often miss brief awakenings or the terminal wake-up.
        let tst = asleepSamples.reduce(0) {
            $0 + Int($1.endDate.timeIntervalSince($1.startDate) / 60)
        }
        if tst > 0 {
            result.totalSleepMinutes = tst
            result.sourceFields.insert("totalSleepMinutes")
        }

        // --- Final wake time: start of the awake period that led to getting up ---
        // We anchor on outOfBedTime: the terminal awakening is the latest awake
        // sample whose start is before outOfBedTime. This avoids mistaking a
        // brief 3 AM awakening for the final wake when the watch lost contact
        // afterward and recorded no further data.
        if let outOfBed = result.outOfBedTime {
            if let terminalAwake = awakeSamples
                .filter({ $0.startDate < outOfBed })
                .max(by: { $0.startDate < $1.startDate }) {
                result.finalWakeTime = terminalAwake.startDate
            } else if let lastAsleep = asleepSamples.last {
                // No awake sample found before outOfBed — use end of last sleep stage
                result.finalWakeTime = lastAsleep.endDate
            }
            result.sourceFields.insert("finalWakeTime")
        }

        // --- WASO & awakenings: only mid-night awakenings (after first sleep,
        // before the terminal wake-up). The terminal awake period is not "waking
        // during the night" — it's the morning wake-up.
        if let firstAsleep = asleepSamples.first,
           let terminalWakeStart = result.finalWakeTime {
            let midNightAwake = awakeSamples.filter {
                $0.startDate >= firstAsleep.startDate && $0.startDate < terminalWakeStart
            }
            result.numberOfAwakenings = midNightAwake.count
            result.sourceFields.insert("numberOfAwakenings")

            // WASO derived from TST so the math always reconciles:
            // TIB = SOL + TST + WASO  →  WASO = TIB - SOL - TST
            if let tst = result.totalSleepMinutes,
               let bed = result.bedTime,
               let outOfBed = result.outOfBedTime {
                let tib = max(0, Int(outOfBed.timeIntervalSince(bed) / 60))
                let sol = result.sleepOnsetMinutes ?? 0
                result.wakeAfterSleepOnset = max(0, tib - sol - tst)
            } else {
                result.wakeAfterSleepOnset = midNightAwake.reduce(0) {
                    $0 + Int($1.endDate.timeIntervalSince($1.startDate) / 60)
                }
            }
            result.sourceFields.insert("wakeAfterSleepOnset")
        }

        return result
    }
}

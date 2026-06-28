import Foundation
import SwiftUI

// MARK: - Insight model

struct SleepInsight: Identifiable {
    let id = UUID()
    let category: InsightCategory
    let priority: Int        // 0 = highest priority
    let title: String
    let body: String
    let icon: String
    let color: Color
    let actionLabel: String?
    let actionTarget: InsightAction?

    enum InsightCategory {
        case windowAdjustment, stimulusControl, progress, hygiene, cognitive, compliance
    }

    enum InsightAction {
        case openExercise(String)   // exercise ID
        case openProgress
        case openSettings
    }
}

// MARK: - Engine

struct SleepCoachEngine {

    // Minimum entries required before generating most insights
    private static let minEntries = 3

    static func insights(entries: [SleepEntry], profile: UserProfile?, programDay: Int) -> [SleepInsight] {
        let completed = entries
            .filter { $0.morningCompleted && $0.timeInBed > 0 }
            .sorted { $0.date > $1.date }

        var results: [SleepInsight] = []

        results += complianceInsights(completed: completed, programDay: programDay)

        guard completed.count >= minEntries else { return results.sorted { $0.priority < $1.priority } }

        results += windowInsights(completed: completed, profile: profile)
        results += stimulusControlInsights(completed: completed)
        results += hygieneInsights(completed: completed)
        results += cognitiveInsights(completed: completed)
        results += progressInsights(completed: completed, programDay: programDay, profile: profile)

        return results.sorted { $0.priority < $1.priority }
    }

    // MARK: - Compliance

    private static func complianceInsights(completed: [SleepEntry], programDay: Int) -> [SleepInsight] {
        guard programDay >= 3 else { return [] }
        let last7Days = 7
        let expectedEntries = min(programDay, last7Days)
        let actualEntries = completed.prefix(last7Days).count
        let ratio = Double(actualEntries) / Double(expectedEntries)

        if completed.isEmpty {
            return [SleepInsight(
                category: .compliance,
                priority: 0,
                title: "Start Your Sleep Diary",
                body: "Logging is the engine of CBT-I. Without data, we can't calibrate your sleep window or track your progress. Open the Morning Log each day after waking.",
                icon: "square.and.pencil",
                color: .orange,
                actionLabel: nil,
                actionTarget: nil
            )]
        }

        if ratio < 0.5 && programDay >= 5 {
            return [SleepInsight(
                category: .compliance,
                priority: 1,
                title: "Keep the Diary Going",
                body: "You've logged \(actualEntries) of the last \(expectedEntries) nights. Consistency matters — even a rough estimate beats skipping. The diary is your most powerful treatment tool.",
                icon: "exclamationmark.circle.fill",
                color: .orange,
                actionLabel: nil,
                actionTarget: nil
            )]
        }
        return []
    }

    // MARK: - Sleep window adjustment

    private static func windowInsights(completed: [SleepEntry], profile: UserProfile?) -> [SleepInsight] {
        let recent = Array(completed.prefix(7))
        guard recent.count >= 5 else { return [] }

        let avgSE = recent.reduce(0.0) { $0 + $1.sleepEfficiency } / Double(recent.count)
        let daysAbove85 = recent.filter { $0.sleepEfficiency >= 85 }.count
        let daysAbove90 = recent.filter { $0.sleepEfficiency >= 90 }.count
        let avgTST = recent.reduce(0.0) { $0 + Double($1.totalSleepTime) } / Double(recent.count)
        let avgTSTh = avgTST / 60

        if daysAbove90 >= 5 {
            return [SleepInsight(
                category: .windowAdjustment,
                priority: 0,
                title: "Extend Your Sleep Window",
                body: String(format: "Your sleep efficiency has been above 90%% for 5 or more nights (avg %.0f%%). You've earned it — add 15–30 minutes to your time in bed. Adjust in Settings or tap Apply in Progress.", avgSE),
                icon: "arrow.up.circle.fill",
                color: .green,
                actionLabel: "Go to Progress",
                actionTarget: .openProgress
            )]
        }

        if daysAbove85 >= 5 {
            return [SleepInsight(
                category: .windowAdjustment,
                priority: 1,
                title: "Window Expansion Available",
                body: String(format: "Great work — SE has been at or above 85%% for %d of the last 7 nights (avg %.0f%%). Consider adding 15 minutes to your sleep window this week.", daysAbove85, avgSE),
                icon: "arrow.up.right.circle.fill",
                color: Color(red: 0.2, green: 0.7, blue: 0.3),
                actionLabel: "Adjust in Settings",
                actionTarget: .openSettings
            )]
        }

        if avgSE < 80 && recent.count >= 5 {
            return [SleepInsight(
                category: .windowAdjustment,
                priority: 1,
                title: "Stay the Course",
                body: String(format: "Your average sleep efficiency this week is %.0f%%. Sleep restriction works through mild sleep pressure — keep your bedtime and wake time strict, even on weekends. Improvement typically arrives by week 2–3.", avgSE),
                icon: "clock.badge.exclamationmark.fill",
                color: .indigo,
                actionLabel: nil,
                actionTarget: nil
            )]
        }

        if avgSE >= 80 && avgSE < 85 {
            return [SleepInsight(
                category: .windowAdjustment,
                priority: 2,
                title: "Almost There",
                body: String(format: "Average SE is %.0f%% — you're close to the 85%% threshold for window expansion. Keep your wake time rigid and avoid lying in bed awake.", avgSE),
                icon: "chart.line.uptrend.xyaxis",
                color: .indigo,
                actionLabel: nil,
                actionTarget: nil
            )]
        }

        // Positive: good SE
        if avgSE >= 85 {
            let _ = avgTSTh  // suppress unused
            return [SleepInsight(
                category: .windowAdjustment,
                priority: 3,
                title: "Sleep Efficiency on Track",
                body: String(format: "Your 7-night average SE is %.0f%% — right in the target zone. Keep your schedule consistent.", avgSE),
                icon: "checkmark.seal.fill",
                color: .green,
                actionLabel: nil,
                actionTarget: nil
            )]
        }

        return []
    }

    // MARK: - Stimulus control

    private static func stimulusControlInsights(completed: [SleepEntry]) -> [SleepInsight] {
        let recent = Array(completed.prefix(7))
        guard recent.count >= 3 else { return [] }

        var results: [SleepInsight] = []

        let avgSOL = recent.reduce(0.0) { $0 + Double($1.sleepOnsetMinutes) } / Double(recent.count)
        let avgWASO = recent.reduce(0.0) { $0 + Double($1.wakeAfterSleepOnset) } / Double(recent.count)
        let avgAwakenings = recent.reduce(0.0) { $0 + Double($1.numberOfAwakenings) } / Double(recent.count)

        if avgSOL > 30 {
            results.append(SleepInsight(
                category: .stimulusControl,
                priority: 2,
                title: "Trouble Falling Asleep",
                body: String(format: "Your average sleep onset is %.0f minutes. The stimulus control rule: only get into bed when you're genuinely sleepy (eyes heavy, nodding off) — not just tired or anxious. If you're not asleep within 20 minutes, get up.", avgSOL),
                icon: "moon.zzz.fill",
                color: .indigo,
                actionLabel: nil,
                actionTarget: nil
            ))
        }

        if avgWASO > 45 {
            let advice = avgAwakenings > 3
                ? "You're averaging \(Int(avgAwakenings.rounded())) awakenings per night. Each time you wake, apply the 20-minute rule: if you can't drift back within 20 minutes, get up and do something calm in dim light."
                : String(format: "You're spending an average of %.0f minutes awake during the night. Make sure your bed is associated only with sleep — no reading, scrolling, or worrying in bed.", avgWASO)
            results.append(SleepInsight(
                category: .stimulusControl,
                priority: 2,
                title: "Waking During the Night",
                body: advice,
                icon: "figure.walk",
                color: .purple,
                actionLabel: nil,
                actionTarget: nil
            ))
        }

        return results
    }

    // MARK: - Sleep hygiene

    private static func hygieneInsights(completed: [SleepEntry]) -> [SleepInsight] {
        let recent = Array(completed.prefix(7))
        guard recent.count >= 3 else { return [] }

        var results: [SleepInsight] = []

        let napNights = recent.filter { $0.napMinutes > 20 }.count
        let alcoholNights = recent.filter { $0.alcoholServings > 0 }.count
        let caffeineHigh = recent.filter { $0.caffeineServings > 2 }.count
        let exerciseNights = recent.filter { $0.exerciseMinutes >= 30 }.count

        if napNights >= 2 {
            results.append(SleepInsight(
                category: .hygiene,
                priority: 3,
                title: "Avoid Daytime Naps",
                body: "You've napped on \(napNights) of the last \(recent.count) days. Napping bleeds off sleep pressure — the very pressure that CBT-I sleep restriction is trying to build. Skip naps, even if you feel exhausted; that tiredness is working for you.",
                icon: "sun.max.fill",
                color: .orange,
                actionLabel: nil,
                actionTarget: nil
            ))
        }

        if alcoholNights >= 3 {
            results.append(SleepInsight(
                category: .hygiene,
                priority: 4,
                title: "Alcohol Disrupts Sleep Architecture",
                body: "Alcohol logged on \(alcoholNights) nights this week. While it helps you fall asleep, it fragments the second half of the night and suppresses REM sleep. Try to avoid alcohol within 3 hours of bedtime.",
                icon: "drop.triangle.fill",
                color: .red,
                actionLabel: nil,
                actionTarget: nil
            ))
        }

        if caffeineHigh >= 2 {
            results.append(SleepInsight(
                category: .hygiene,
                priority: 4,
                title: "Watch Caffeine Timing",
                body: "High caffeine intake noted on \(caffeineHigh) days this week. Caffeine has a half-life of 5–7 hours — a 3 PM coffee still has half its effect at 10 PM. Try cutting off caffeine before noon if you struggle to fall asleep.",
                icon: "cup.and.saucer.fill",
                color: Color(red: 0.55, green: 0.35, blue: 0.10),
                actionLabel: nil,
                actionTarget: nil
            ))
        }

        if exerciseNights >= 3 {
            results.append(SleepInsight(
                category: .hygiene,
                priority: 6,
                title: "Exercise Helping Your Sleep",
                body: "You've exercised \(exerciseNights) days this week — that's excellent. Regular moderate exercise is one of the most effective non-pharmacological sleep aids. Keep it up.",
                icon: "figure.run",
                color: .green,
                actionLabel: nil,
                actionTarget: nil
            ))
        }

        return results
    }

    // MARK: - Cognitive

    private static func cognitiveInsights(completed: [SleepEntry]) -> [SleepInsight] {
        let recent = Array(completed.prefix(7))
        guard recent.count >= 4 else { return [] }

        var results: [SleepInsight] = []

        let avgQuality = recent.reduce(0.0) { $0 + Double($1.sleepQuality) } / Double(recent.count)
        let avgSE = recent.reduce(0.0) { $0 + $1.sleepEfficiency } / Double(recent.count)
        let avgMood = recent.reduce(0.0) { $0 + Double($1.morningMood) } / Double(recent.count)

        // Low perceived quality despite decent SE = cognitive distortion
        if avgQuality < 2.5 && avgSE >= 80 {
            results.append(SleepInsight(
                category: .cognitive,
                priority: 3,
                title: "Your Sleep May Be Better Than It Feels",
                body: String(format: "You're rating sleep quality at %.1f/5 while your actual efficiency is %.0f%%. Insomnia often distorts self-perception of sleep — we tend to overestimate how long we were awake. Try a thought record to examine that belief.", avgQuality, avgSE),
                icon: "brain.head.profile",
                color: .purple,
                actionLabel: "Open Thought Record",
                actionTarget: .openExercise("thought_record")
            ))
        }

        // Consistently low mood — suggest relaxation
        if avgMood < 2.5 {
            results.append(SleepInsight(
                category: .cognitive,
                priority: 4,
                title: "Low Morning Mood",
                body: "Your morning mood has been low this week. Pre-sleep relaxation can dampen the stress response that fragments sleep. Try PMR or the 4-7-8 breathing exercise tonight before bed.",
                icon: "heart.fill",
                color: .pink,
                actionLabel: "Try Breathing",
                actionTarget: .openExercise("breathing")
            ))
        }

        return results
    }

    // MARK: - Progress / motivation

    private static func progressInsights(completed: [SleepEntry], programDay: Int, profile: UserProfile?) -> [SleepInsight] {
        var results: [SleepInsight] = []
        let week = profile?.currentWeek ?? 1

        // Week milestones
        if programDay == 7 {
            let avgSE = completed.prefix(7).reduce(0.0) { $0 + $1.sleepEfficiency } / Double(min(completed.count, 7))
            results.append(SleepInsight(
                category: .progress,
                priority: 5,
                title: "One Week In",
                body: String(format: "You've completed your first week. Average sleep efficiency: %.0f%%. CBT-I research shows most people see meaningful improvement by week 2–3. You're doing the work.", avgSE),
                icon: "star.fill",
                color: .yellow,
                actionLabel: nil,
                actionTarget: nil
            ))
        }

        // Positive trend: last 3 nights better than 3 before
        if completed.count >= 6 {
            let newer = Array(completed.prefix(3))
            let older = Array(completed.dropFirst(3).prefix(3))
            let newerSE = newer.reduce(0.0) { $0 + $1.sleepEfficiency } / Double(newer.count)
            let olderSE = older.reduce(0.0) { $0 + $1.sleepEfficiency } / Double(older.count)
            if newerSE - olderSE > 8 {
                results.append(SleepInsight(
                    category: .progress,
                    priority: 5,
                    title: "Improving Trend",
                    body: String(format: "Your sleep efficiency has improved by %.0f percentage points compared to the previous three nights. Keep the schedule rigid — this momentum is real.", newerSE - olderSE),
                    icon: "arrow.up.right",
                    color: .green,
                    actionLabel: nil,
                    actionTarget: nil
                ))
            }
        }

        // Week-specific psychoeducation
        switch week {
        case 1:
            results.append(SleepInsight(
                category: .progress,
                priority: 7,
                title: "Why You May Feel Worse First",
                body: "Sleep restriction often makes the first 5–7 nights harder. That's not failure — it's the treatment working. You're building sleep pressure. Most people experience the first good night between days 5–10.",
                icon: "info.circle.fill",
                color: .indigo,
                actionLabel: nil,
                actionTarget: nil
            ))
        case 2:
            results.append(SleepInsight(
                category: .progress,
                priority: 7,
                title: "Week 2: Stimulus Control Focus",
                body: "This week, pay close attention to where and when you try to sleep. Bed is only for sleep. Keep the 20-minute rule: up and out of bed if you can't sleep. Your brain is re-learning the association between bed and sleepiness.",
                icon: "bed.double.fill",
                color: .indigo,
                actionLabel: nil,
                actionTarget: nil
            ))
        case 3, 4:
            results.append(SleepInsight(
                category: .progress,
                priority: 7,
                title: "Mid-Program Check-In",
                body: "Weeks 3–4 are often when CBT-I starts to click. If you haven't already, add a relaxation practice (PMR, breathing) to your pre-bed wind-down. It reduces the arousal that keeps insomniacs awake.",
                icon: "sparkles",
                color: .cyan,
                actionLabel: "Try PMR",
                actionTarget: .openExercise("pmr")
            ))
        case 5, 6:
            results.append(SleepInsight(
                category: .progress,
                priority: 7,
                title: "Consolidating Your Gains",
                body: "You're in the consolidation phase. Focus on keeping your wake time fixed and only expanding your window when SE hits 90%+ consistently. The goal now is durability, not just efficiency.",
                icon: "lock.fill",
                color: .teal,
                actionLabel: nil,
                actionTarget: nil
            ))
        case 7, 8:
            results.append(SleepInsight(
                category: .progress,
                priority: 7,
                title: "Approaching the Finish Line",
                body: "In the final weeks, the CBT-I work shifts to maintenance. You should have a personalized sleep window that works for you. Review your relapse prevention plan: know your early warning signs and what to do if a bad patch returns.",
                icon: "flag.checkered",
                color: .green,
                actionLabel: nil,
                actionTarget: nil
            ))
        default: break
        }

        return results
    }
}

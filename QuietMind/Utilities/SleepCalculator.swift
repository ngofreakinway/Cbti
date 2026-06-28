import Foundation

enum SleepCalculator {
    /// Format minutes as "Xh Ym"
    static func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    /// Derive a recommended bedtime given a fixed wake time and desired TIB in minutes
    static func bedtime(wakeHour: Int, wakeMinute: Int, tibMinutes: Int) -> (hour: Int, minute: Int) {
        let wakeTotal = wakeHour * 60 + wakeMinute
        var bedTotal = wakeTotal - tibMinutes
        if bedTotal < 0 { bedTotal += 24 * 60 }
        return (bedTotal / 60, bedTotal % 60)
    }

    /// Interpret SE and return an adjustment recommendation
    static func sleepWindowAdjustment(sleepEfficiency: Double, currentTIBMinutes: Int) -> (adjustment: Int, message: String) {
        switch sleepEfficiency {
        case 90...:
            let add = 15
            return (add, "Great efficiency (\(Int(sleepEfficiency))%)! Expand your window by \(add) minutes — move bedtime earlier.")
        case 85..<90:
            return (0, "Good efficiency (\(Int(sleepEfficiency))%). Keep your current window this week.")
        default:
            let subtract = 15
            let newTIB = max(5 * 60, currentTIBMinutes - subtract)
            let actualSubtract = currentTIBMinutes - newTIB
            if actualSubtract == 0 {
                return (0, "Efficiency is low (\(Int(sleepEfficiency))%) but you're at the minimum 5-hour window.")
            }
            return (-subtract, "Efficiency is low (\(Int(sleepEfficiency))%). Restrict by \(subtract) minutes — move bedtime later.")
        }
    }
}

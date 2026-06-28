import SwiftUI
import Charts

struct ProgressView: View {
    @EnvironmentObject var store: AppStore

    private var entries: [SleepEntry] { store.last7Entries }
    private var avgSE: Double { store.averageSleepEfficiency7d }
    private var avgTST: Double { store.averageTST7d }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 7-day summary cards
                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Avg Efficiency",
                            value: avgSE > 0 ? String(format: "%.0f%%", avgSE) : "—",
                            icon: "percent",
                            color: seColor(avgSE),
                            subtitle: seLabel(avgSE)
                        )
                        SummaryCard(
                            title: "Avg Sleep Time",
                            value: avgTST > 0 ? SleepCalculator.formatMinutes(Int(avgTST)) : "—",
                            icon: "moon.fill",
                            color: .indigo,
                            subtitle: "per night"
                        )
                    }
                    .padding(.horizontal)

                    // Sleep efficiency chart
                    if !entries.isEmpty {
                        SleepEfficiencyChart(entries: entries)
                            .padding(.horizontal)

                        TotalSleepChart(entries: entries)
                            .padding(.horizontal)

                        SleepOnsetChart(entries: entries)
                            .padding(.horizontal)
                    } else {
                        ContentUnavailableView(
                            "No data yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Complete your morning log for a few days to see charts here.")
                        )
                        .padding(.top, 40)
                    }

                    // Sleep restriction guidance
                    if avgSE > 0, let profile = store.profile {
                        SleepWindowGuidanceCard(
                            sleepEfficiency: avgSE,
                            profile: profile,
                            recommendedTIB: store.recommendedSleepWindowMinutes()
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
        }
    }

    private func seColor(_ se: Double) -> Color {
        se >= 90 ? .green : se >= 85 ? .yellow : se > 0 ? .red : .secondary
    }
    private func seLabel(_ se: Double) -> String {
        se >= 90 ? "Excellent" : se >= 85 ? "On target" : se > 0 ? "Below goal" : "No data"
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Sleep Efficiency Chart

private struct SleepEfficiencyChart: View {
    let entries: [SleepEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sleep Efficiency (7 days)")
                .font(.headline)
            Text("Goal: ≥ 85%")
                .font(.caption).foregroundStyle(.secondary)

            Chart {
                RuleMark(y: .value("Goal", 85))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(dash: [4]))
                    .annotation(position: .trailing) {
                        Text("85%").font(.caption2).foregroundStyle(.green)
                    }

                ForEach(entries.filter(\.morningCompleted)) { entry in
                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("SE", entry.sleepEfficiency)
                    )
                    .foregroundStyle(Color.indigo)

                    PointMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("SE", entry.sleepEfficiency)
                    )
                    .foregroundStyle(entry.sleepEfficiency >= 85 ? Color.green : Color.red)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 75, 85, 100]) { val in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Total Sleep Chart

private struct TotalSleepChart: View {
    let entries: [SleepEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Sleep Time (7 days)")
                .font(.headline)

            Chart {
                ForEach(entries.filter(\.morningCompleted)) { entry in
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("TST (min)", entry.totalSleepTime)
                    )
                    .foregroundStyle(Color.indigo.gradient)
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks { val in
                    AxisGridLine()
                    if let mins = val.as(Int.self) {
                        AxisValueLabel { Text(SleepCalculator.formatMinutes(mins)).font(.caption2) }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Sleep Onset Chart

private struct SleepOnsetChart: View {
    let entries: [SleepEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sleep Onset Latency (7 days)")
                .font(.headline)
            Text("Goal: < 30 minutes")
                .font(.caption).foregroundStyle(.secondary)

            Chart {
                RuleMark(y: .value("Goal", 30))
                    .foregroundStyle(Color.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(dash: [4]))

                ForEach(entries.filter(\.morningCompleted)) { entry in
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("SOL (min)", entry.sleepOnsetMinutes)
                    )
                    .foregroundStyle((entry.sleepOnsetMinutes <= 30 ? Color.green : Color.orange).gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Sleep Window Guidance

private struct SleepWindowGuidanceCard: View {
    let sleepEfficiency: Double
    let profile: UserProfile
    let recommendedTIB: Int

    private var adjustment: (Int, String) {
        let currentTIB = Int(profile.prescribedTimeInBedHours * 60)
        return SleepCalculator.sleepWindowAdjustment(sleepEfficiency: sleepEfficiency, currentTIBMinutes: currentTIB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sleep Window Recommendation", systemImage: "bed.double.fill")
                .font(.headline)

            Text(adjustment.1)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            let newTIB = Int(profile.prescribedTimeInBedHours * 60) + adjustment.0
            let (h, m) = SleepCalculator.bedtime(
                wakeHour: profile.prescribedWakeTimeHour,
                wakeMinute: profile.prescribedWakeTimeMinute,
                tibMinutes: newTIB
            )

            HStack {
                VStack(alignment: .leading) {
                    Text("Suggested Bedtime")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%02d:%02d", h, m))
                        .font(.title2.bold()).foregroundStyle(.indigo)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Wake Time (fixed)")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%02d:%02d", profile.prescribedWakeTimeHour, profile.prescribedWakeTimeMinute))
                        .font(.title2.bold()).foregroundStyle(.orange)
                }
            }

            Text("Adjust your prescribed window in Settings after reviewing. These are guidelines — use clinical judgment if working with a therapist.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

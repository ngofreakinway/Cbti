import SwiftUI
import Charts

struct SleepProgressView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdjustConfirm = false

    private var entries: [SleepEntry] { store.last7Entries }
    private var avgSE: Double { store.averageSleepEfficiency7d }
    private var avgTST: Double { store.averageTST7d }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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
                            title: "Avg Sleep",
                            value: avgTST > 0 ? SleepCalculator.formatMinutes(Int(avgTST)) : "—",
                            icon: "moon.fill",
                            color: .indigo,
                            subtitle: "per night"
                        )
                    }
                    .padding(.horizontal, 20)

                    if entries.filter(\.morningCompleted).isEmpty {
                        ContentUnavailableView(
                            "No data yet",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Complete your morning log for a few nights to see charts here.")
                        )
                        .padding(.top, 40)
                    } else {
                        SleepEfficiencyChart(entries: entries)
                            .padding(.horizontal, 20)

                        TotalSleepChart(entries: entries)
                            .padding(.horizontal, 20)

                        SleepOnsetChart(entries: entries)
                            .padding(.horizontal, 20)
                    }

                    if avgSE > 0, let profile = store.profile {
                        SleepWindowGuidanceCard(
                            sleepEfficiency: avgSE,
                            profile: profile,
                            recommendedTIB: store.recommendedSleepWindowMinutes(),
                            onApply: { store.applyWindowAdjustment() }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    private func seColor(_ se: Double) -> Color {
        se >= 90 ? .green : se >= 85 ? Color(red: 0.75, green: 0.55, blue: 0) : se > 0 ? .red : .secondary
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
                .font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold()).foregroundStyle(color)
            Text(subtitle)
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Efficiency Chart

private struct SleepEfficiencyChart: View {
    let entries: [SleepEntry]
    private var completed: [SleepEntry] { entries.filter(\.morningCompleted) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Efficiency").font(.headline)
                Text("Goal: ≥ 85% — data from 7 nights")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Chart {
                RuleMark(y: .value("Goal", 85))
                    .foregroundStyle(Color.green.opacity(0.45))
                    .lineStyle(StrokeStyle(dash: [5, 3]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("85%").font(.caption2).foregroundStyle(.green)
                    }

                ForEach(completed) { entry in
                    let se = entry.sleepEfficiency
                    AreaMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("SE", se)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.18), Color.indigo.opacity(0.03)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("SE", se)
                    )
                    .foregroundStyle(Color.indigo)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("SE", se)
                    )
                    .foregroundStyle(se >= 85 ? Color.green : Color.red)
                    .symbolSize(40)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 75, 85, 100]) {
                    AxisGridLine().foregroundStyle(Color(.systemGray5))
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 190)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Total Sleep Chart

private struct TotalSleepChart: View {
    let entries: [SleepEntry]
    private var completed: [SleepEntry] { entries.filter(\.morningCompleted) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Sleep Time").font(.headline)
                Text("7-day history").font(.caption).foregroundStyle(.secondary)
            }

            Chart {
                RuleMark(y: .value("Target", 7 * 60))
                    .foregroundStyle(Color.indigo.opacity(0.35))
                    .lineStyle(StrokeStyle(dash: [5, 3]))

                ForEach(completed) { entry in
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("TST (min)", entry.totalSleepTime)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [Color.indigo.opacity(0.7), Color.indigo], startPoint: .bottom, endPoint: .top)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .chartYAxis {
                AxisMarks { val in
                    AxisGridLine().foregroundStyle(Color(.systemGray5))
                    if let mins = val.as(Int.self) {
                        AxisValueLabel { Text(SleepCalculator.formatMinutes(mins)).font(.caption2) }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Onset Chart

private struct SleepOnsetChart: View {
    let entries: [SleepEntry]
    private var completed: [SleepEntry] { entries.filter(\.morningCompleted) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Onset Latency").font(.headline)
                Text("Goal: < 30 minutes").font(.caption).foregroundStyle(.secondary)
            }

            Chart {
                RuleMark(y: .value("Goal", 30))
                    .foregroundStyle(Color.orange.opacity(0.45))
                    .lineStyle(StrokeStyle(dash: [5, 3]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("30m").font(.caption2).foregroundStyle(.orange)
                    }

                ForEach(completed) { entry in
                    let sol = entry.sleepOnsetMinutes
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("SOL (min)", sol)
                    )
                    .foregroundStyle((sol <= 30 ? Color.green : Color.orange).gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sleep Window Guidance

private struct SleepWindowGuidanceCard: View {
    let sleepEfficiency: Double
    let profile: UserProfile
    let recommendedTIB: Int
    let onApply: () -> Void

    @State private var showConfirm = false

    private var adjustment: (adjustment: Int, message: String) {
        let currentTIB = Int(profile.prescribedTimeInBedHours * 60)
        return SleepCalculator.sleepWindowAdjustment(
            sleepEfficiency: sleepEfficiency,
            currentTIBMinutes: currentTIB
        )
    }

    private var suggestedBedtime: (hour: Int, minute: Int) {
        let newTIB = max(5 * 60, Int(profile.prescribedTimeInBedHours * 60) + adjustment.adjustment)
        return SleepCalculator.bedtime(
            wakeHour: profile.prescribedWakeTimeHour,
            wakeMinute: profile.prescribedWakeTimeMinute,
            tibMinutes: newTIB
        )
    }

    private func timeString(_ hour: Int, _ minute: Int) -> String {
        let isPM = hour >= 12
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", h, minute, isPM ? "PM" : "AM")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Weekly Adjustment", systemImage: "bed.double.fill")
                .font(.headline)

            Text(adjustment.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Suggested Bedtime").font(.caption).foregroundStyle(.secondary)
                    Text(timeString(suggestedBedtime.hour, suggestedBedtime.minute))
                        .font(.title2.bold()).foregroundStyle(.indigo)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Fixed Wake Time").font(.caption).foregroundStyle(.secondary)
                    Text(timeString(profile.prescribedWakeTimeHour, profile.prescribedWakeTimeMinute))
                        .font(.title2.bold()).foregroundStyle(.orange)
                }
            }

            if adjustment.adjustment != 0 {
                Button(action: { showConfirm = true }) {
                    HStack {
                        Image(systemName: adjustment.adjustment > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        Text(adjustment.adjustment > 0 ? "Apply: Move Bedtime Earlier" : "Apply: Move Bedtime Later")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.indigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .alert("Apply Adjustment?", isPresented: $showConfirm) {
                    Button("Apply") { onApply() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(adjustment.adjustment > 0
                         ? "Your prescribed bedtime will move 15 minutes earlier."
                         : "Your prescribed bedtime will move 15 minutes later to consolidate sleep.")
                }
            } else {
                Label("No adjustment needed this week — keep your current window.", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            Text("Review weekly. Consult your therapist if you have clinical support.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

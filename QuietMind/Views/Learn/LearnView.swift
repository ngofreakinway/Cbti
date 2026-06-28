import SwiftUI

struct LearnView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedModule: WorkbookModule?

    private var modules: [WorkbookModule] {
        WorkbookModule.modules(for: store.profile)
    }

    private var groupedModules: [(week: Int, modules: [WorkbookModule])] {
        let grouped = Dictionary(grouping: modules, by: \.week)
        return grouped.keys.sorted().map { week in
            (week: week, modules: grouped[week]!.sorted { $0.id < $1.id })
        }
    }

    private var completedIDs: Set<String> {
        Set(store.profile?.completedModuleIDs ?? [])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ProgressHeader(
                        completed: modules.filter { completedIDs.contains($0.id) }.count,
                        total: modules.count
                    )
                    .padding(.horizontal, 20)

                    ForEach(groupedModules, id: \.week) { group in
                        weekSection(group)
                    }
                }
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Learn")
            .navigationDestination(item: $selectedModule) { module in
                ModuleDetailView(module: module)
                    .environmentObject(store)
            }
        }
    }

    private func weekSection(_ group: (week: Int, modules: [WorkbookModule])) -> some View {
        let doneCount = group.modules.filter { completedIDs.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(weekLabel(group.week))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                if doneCount > 0 {
                    Text("\(doneCount)/\(group.modules.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)

            ForEach(group.modules) { module in
                ModuleCard(
                    module: module,
                    isCompleted: completedIDs.contains(module.id)
                )
                .onTapGesture { selectedModule = module }
                .padding(.horizontal, 20)
            }
        }
    }

    private func weekLabel(_ week: Int) -> String {
        switch week {
        case 1: return "Week 1 — Foundations"
        case 2: return "Week 2 — Core Techniques"
        case 3: return "Week 3 — Sleep Hygiene"
        case 4: return "Week 4 — Cognitive Skills"
        case 5: return "Week 5 — Relaxation"
        case 6: return "Week 6 — Personalized"
        case 7...: return "Maintenance"
        default: return "Week \(week)"
        }
    }
}

// MARK: - Progress Header

private struct ProgressHeader: View {
    let completed: Int
    let total: Int

    private var progress: Double { total > 0 ? Double(completed) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Progress").font(.headline)
                Text("\(completed) of \(total) modules completed")
                    .font(.caption).foregroundStyle(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.indigo, Color(red: 0.50, green: 0.25, blue: 0.85)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * progress)
                            .animation(.easeOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 7)
                .padding(.top, 4)
            }

            ZStack {
                Circle().stroke(Color(.systemGray5), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.indigo, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.caption2.bold()).foregroundStyle(.indigo)
            }
            .frame(width: 54, height: 54)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Module Card

private struct ModuleCard: View {
    let module: WorkbookModule
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isCompleted ? accentColor : accentColor.opacity(0.12))
                    .frame(width: 54, height: 54)
                Image(systemName: isCompleted ? "checkmark" : module.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isCompleted ? .white : accentColor)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isCompleted)

            VStack(alignment: .leading, spacing: 3) {
                Text(module.title).font(.headline).foregroundStyle(.primary)
                Text(module.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text("\(module.sections.count) sections").font(.caption2).foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                .font(isCompleted ? .title3 : .body)
                .foregroundStyle(isCompleted ? .green : Color(.systemGray3))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Color.green.opacity(0.28) : Color.clear, lineWidth: 1.5)
        )
    }

    private var accentColor: Color {
        switch module.color {
        case "indigo":  return .indigo
        case "teal":    return .teal
        case "purple":  return .purple
        case "orange":  return .orange
        case "green":   return .green
        case "red":     return .red
        case "cyan":    return .cyan
        case "blue":    return .blue
        case "yellow":  return Color(red: 0.78, green: 0.58, blue: 0)
        case "mint":    return .mint
        default:        return .indigo
        }
    }
}

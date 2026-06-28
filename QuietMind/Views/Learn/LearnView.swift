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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(groupedModules, id: \.week) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(weekLabel(group.week))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            ForEach(group.modules) { module in
                                ModuleCard(
                                    module: module,
                                    isCompleted: store.profile?.completedModuleIDs.contains(module.id) ?? false
                                )
                                .onTapGesture { selectedModule = module }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Learn")
            .navigationDestination(item: $selectedModule) { module in
                ModuleDetailView(module: module)
                    .environmentObject(store)
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

private struct ModuleCard: View {
    let module: WorkbookModule
    let isCompleted: Bool

    private var cardColor: Color {
        Color(module.color) // Relies on asset catalog color names matching; falls back gracefully
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: module.icon)
                .font(.title2)
                .foregroundStyle(isCompleted ? .white : accentColor)
                .frame(width: 52, height: 52)
                .background(isCompleted ? accentColor : accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(module.title).font(.headline)
                Text(module.subtitle).font(.caption).foregroundStyle(.secondary)
                Text("\(module.sections.count) sections")
                    .font(.caption2).foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: isCompleted ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(isCompleted ? .green : .secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }

    private var accentColor: Color {
        switch module.color {
        case "indigo": return .indigo
        case "teal": return .teal
        case "purple": return .purple
        case "orange": return .orange
        case "green": return .green
        case "red": return .red
        case "cyan": return .cyan
        case "blue": return .blue
        case "yellow": return .yellow
        case "mint": return .mint
        default: return .indigo
        }
    }
}

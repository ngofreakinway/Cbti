import SwiftUI

struct ModuleDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let module: WorkbookModule

    @State private var currentSection = 0
    @State private var reflectionTexts: [String: String] = [:]
    @State private var linkedExercise: LinkedExercise?

    private var section: ModuleSection { module.sections[currentSection] }
    private var isLast: Bool { currentSection == module.sections.count - 1 }
    private var isCompleted: Bool { store.profile?.completedModuleIDs.contains(module.id) ?? false }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section progress capsules
                HStack(spacing: 4) {
                    ForEach(0..<module.sections.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentSection ? accentColor : Color(.systemGray5))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.25), value: currentSection)
                    }
                }
                .padding(.top, 4)

                // Section header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Section \(currentSection + 1) of \(module.sections.count)")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(section.title)
                        .font(.title2.bold())
                }

                // Body text
                MarkdownText(section.body)

                // Linked exercise — tappable, opens as a sheet
                if let exerciseID = section.exerciseID {
                    ExerciseLinkCard(exerciseID: exerciseID) {
                        linkedExercise = LinkedExercise(id: exerciseID)
                    }
                }

                // Reflection prompt
                if let prompt = section.reflection {
                    ReflectionCard(
                        prompt: prompt,
                        text: Binding(
                            get: { reflectionTexts[section.id] ?? "" },
                            set: { reflectionTexts[section.id] = $0 }
                        )
                    )
                }

                // Navigation buttons
                HStack(spacing: 12) {
                    if currentSection > 0 {
                        Button(action: { withAnimation { currentSection -= 1 } }) {
                            Label("Back", systemImage: "chevron.left")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: advance) {
                        Text(isLast ? (isCompleted ? "Review Complete" : "Mark Complete") : "Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCompleted {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
        }
        .sheet(item: $linkedExercise) { ex in
            ExercisePracticeSheet(exerciseID: ex.id)
        }
    }

    private func advance() {
        if isLast { markComplete() } else { withAnimation { currentSection += 1 } }
    }

    private func markComplete() {
        guard let profile = store.profile else { return }
        if !profile.completedModuleIDs.contains(module.id) {
            profile.completedModuleIDs.append(module.id)
            store.saveProfile()
        }
        dismiss()
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

// MARK: - Linked Exercise identifier

struct LinkedExercise: Identifiable {
    let id: String
}

// MARK: - Exercise Practice Sheet (launched from Learn modules)

private struct ExercisePracticeSheet: View {
    let exerciseID: String

    var body: some View {
        NavigationStack {
            Group {
                switch exerciseID {
                case "breathing":      BreathingExerciseView()
                case "pmr":            PMRView()
                case "thought_record": ThoughtRecordView()
                case "worry_time":     WorryTimeView()
                default:
                    ContentUnavailableView(
                        "Exercise not found",
                        systemImage: "questionmark.circle",
                        description: Text("This exercise isn't available yet.")
                    )
                }
            }
        }
    }
}

// MARK: - Markdown Text (lightweight renderer)

struct MarkdownText: View {
    let raw: String

    init(_ raw: String) { self.raw = raw }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(paragraphs, id: \.self) { para in
                if para.hasPrefix("**") && para.hasSuffix("**") {
                    Text(para.dropFirst(2).dropLast(2))
                        .font(.headline)
                } else {
                    Text(parseInline(para))
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var paragraphs: [String] {
        raw.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseInline(_ text: String) -> AttributedString {
        let result = (try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
        return result
    }
}

// MARK: - Exercise Link Card

private struct ExerciseLinkCard: View {
    let exerciseID: String
    let onTap: () -> Void

    private var exerciseName: String {
        switch exerciseID {
        case "breathing":               return "Breathing Exercise"
        case "pmr":                     return "Progressive Muscle Relaxation"
        case "thought_record":          return "Thought Record"
        case "worry_time":              return "Scheduled Worry Time"
        case "sleep_window_calculator": return "Sleep Window"
        default:                        return exerciseID
        }
    }

    private var icon: String {
        switch exerciseID {
        case "breathing":      return "wind"
        case "pmr":            return "figure.mind.and.body"
        case "thought_record": return "pencil.and.list.clipboard"
        case "worry_time":     return "timer"
        default:               return "play.circle.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.indigo)
                    .frame(width: 44, height: 44)
                    .background(Color.indigo.opacity(0.10))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try it now")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(exerciseName)
                        .font(.headline).foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2).foregroundStyle(.indigo)
            }
            .padding(14)
            .background(Color.indigo.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.indigo.opacity(0.20), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reflection Card

private struct ReflectionCard: View {
    let prompt: ReflectionPrompt
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Reflect", systemImage: "pencil.line")
                .font(.caption.bold()).foregroundStyle(.secondary)
            Text(prompt.question)
                .font(.subheadline.bold())
            TextEditor(text: $text)
                .focused($focused)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Group {
                        if text.isEmpty {
                            Text(prompt.placeholder)
                                .foregroundStyle(.tertiary)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(14)
        .background(Color.indigo.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { focused = true }
    }
}

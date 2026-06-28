import SwiftUI

struct ThoughtRecordView: View {
    @State private var step = 0
    @State private var thought = ""
    @State private var beliefBefore: Double = 70
    @State private var evidence = ""
    @State private var counterEvidence = ""
    @State private var balancedThought = ""
    @State private var beliefAfter: Double = 50

    private let steps = [
        "Identify the Thought",
        "Rate Your Belief",
        "Examine Evidence For",
        "Examine Evidence Against",
        "Create a Balanced Thought",
        "Re-rate Your Belief"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Step progress
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(steps.indices, id: \.self) { i in
                        HStack(spacing: 0) {
                            Circle()
                                .fill(i <= step ? Color.red : Color(.systemGray5))
                                .frame(width: 8, height: 8)
                            if i < steps.count - 1 {
                                Rectangle()
                                    .fill(i < step ? Color.red : Color(.systemGray5))
                                    .frame(width: 20, height: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Step \(step + 1) of \(steps.count)")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(steps[step])
                        .font(.title2.bold())
                        .foregroundStyle(.red)

                    stepContent

                    navigationButtons
                }
                .padding(20)
            }
        }
        .navigationTitle("Thought Record")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            VStack(alignment: .leading, spacing: 8) {
                Text("Write down the sleep-related thought that's bothering you. Be specific and exact — the actual words in your head.")
                    .foregroundStyle(.secondary)
                Text("Examples:")
                    .font(.caption).foregroundStyle(.secondary)
                Text("• \"If I don't sleep 8 hours I'll be useless at work\"\n• \"I'll never be able to sleep normally again\"\n• \"I can feel my health deteriorating from poor sleep\"")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $thought)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4))
                    )
            }

        case 1:
            VStack(alignment: .leading, spacing: 12) {
                Text("How much do you believe this thought right now? (0 = not at all, 100 = completely)")
                    .foregroundStyle(.secondary)
                if !thought.isEmpty {
                    Text("\"\(thought)\"")
                        .font(.subheadline.italic())
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Text("\(Int(beliefBefore))%")
                    .font(.system(size: 52, weight: .thin, design: .rounded))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                Slider(value: $beliefBefore, in: 0...100, step: 5).tint(.red)
            }

        case 2:
            VStack(alignment: .leading, spacing: 8) {
                Text("What evidence supports this thought? Be specific and factual, not emotional.")
                    .foregroundStyle(.secondary)
                Text("Examples: past events, things people said, patterns you've noticed.")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $evidence)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
            }

        case 3:
            VStack(alignment: .leading, spacing: 8) {
                Text("What evidence goes against this thought? Push yourself — this is often the hardest part.")
                    .foregroundStyle(.secondary)
                Text("Ask: Would a friend agree? Have I managed before? Am I predicting the worst? Are there other explanations?")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $counterEvidence)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
            }

        case 4:
            VStack(alignment: .leading, spacing: 8) {
                Text("Write a more balanced thought that takes both sides of the evidence into account. It doesn't have to be positive — just accurate.")
                    .foregroundStyle(.secondary)
                Text("Example: \"Poor sleep is unpleasant and may affect my performance, but I have coped before and have resources to manage.\"")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $balancedThought)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
            }

        case 5:
            VStack(alignment: .leading, spacing: 12) {
                if !balancedThought.isEmpty {
                    Text("Balanced thought:")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\"\(balancedThought)\"")
                        .font(.subheadline.italic())
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Text("Now how much do you believe the original thought?")
                    .foregroundStyle(.secondary)
                Text("\(Int(beliefAfter))%")
                    .font(.system(size: 52, weight: .thin, design: .rounded))
                    .foregroundStyle(beliefAfter < beliefBefore ? .green : .red)
                    .frame(maxWidth: .infinity)
                Slider(value: $beliefAfter, in: 0...100, step: 5)
                    .tint(beliefAfter < beliefBefore ? .green : .red)

                let diff = Int(beliefBefore) - Int(beliefAfter)
                if diff > 0 {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill").foregroundStyle(.green)
                        Text("Belief dropped by \(diff)%. Good work.")
                            .font(.subheadline).foregroundStyle(.green)
                    }
                    .padding(10)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

        default: EmptyView()
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button(action: { step -= 1 }) {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Button(action: { if step < steps.count - 1 { step += 1 } }) {
                Text(step == steps.count - 1 ? "Done" : "Next")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canAdvance ? Color.red : Color(.systemGray4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)
        }
        .padding(.top, 8)
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return !thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4: return !balancedThought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default: return true
        }
    }
}

import Foundation

struct WorkbookModule: Identifiable, Hashable {
    let id: String
    let week: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: String           // SwiftUI color name or hex
    let sections: [ModuleSection]
    let requiredConditions: Set<Condition>  // empty = shown to all

    enum Condition: String {
        case depression, anxiety, pain
    }

    var isUniversal: Bool { requiredConditions.isEmpty }
}

struct ModuleSection: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String            // Markdown-lite body text
    let exerciseID: String?     // Links to a Practice exercise if applicable
    let reflection: ReflectionPrompt?
}

struct ReflectionPrompt: Hashable {
    let question: String
    let placeholder: String
}

// MARK: - Content catalog

extension WorkbookModule {
    static let all: [WorkbookModule] = [
        // WEEK 1
        WorkbookModule(
            id: "w1_understanding_sleep",
            week: 1,
            title: "Understanding Sleep",
            subtitle: "How sleep works and why it breaks down",
            icon: "moon.stars.fill",
            color: "indigo",
            sections: [
                ModuleSection(
                    id: "w1s1",
                    title: "Sleep Architecture",
                    body: """
Sleep is not a uniform state. Your brain cycles through distinct stages every 90–110 minutes:

**Light Sleep (N1/N2)** — the transition into sleep. Easy to wake from; makes up about 50% of the night.

**Deep Sleep (N3)** — slow-wave sleep that restores the body, consolidates memory, and releases growth hormone. Most of it happens in the first half of the night.

**REM Sleep** — the dreaming stage. Critical for emotional processing, mood regulation, and learning. Increases toward morning.

When insomnia disrupts your sleep, deep and REM stages suffer most. Understanding this helps you set realistic expectations: even a good night's sleep contains some wakefulness.
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "What do you notice about your own sleep patterns? When do you tend to wake up?",
                        placeholder: "Write your observations here..."
                    )
                ),
                ModuleSection(
                    id: "w1s2",
                    title: "Two Drivers of Sleep",
                    body: """
Two biological systems regulate when you sleep:

**Sleep Pressure (Process S)** — adenosine accumulates in the brain the longer you're awake. The more pressure built up, the stronger the drive to sleep. Napping releases pressure prematurely, making it harder to fall asleep at night.

**Circadian Rhythm (Process C)** — your internal 24-hour clock promotes alertness during the day and sleepiness at night. It is anchored by your wake time, not your bedtime. A consistent wake time is the single most powerful lever for stabilizing your circadian rhythm.

Insomnia often results from a mismatch between these two systems — staying in bed too long, napping, or variable schedules weaken both.
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "Do you nap regularly? Does your wake time vary on weekends?",
                        placeholder: "Reflect on your current schedule..."
                    )
                ),
                ModuleSection(
                    id: "w1s3",
                    title: "What Keeps Insomnia Going",
                    body: """
Insomnia often starts with a stressor — illness, anxiety, a life event — but it persists because of what we do in response:

- **Spending more time in bed** hoping to catch extra sleep → weakens sleep drive
- **Worrying about sleep** → activates the arousal system at the worst time
- **Clock-watching** → conditions the mind to associate the bedroom with alertness
- **Irregular schedules** → confuses the circadian clock

This is the maintenance model of insomnia, and it's good news: these are all behaviors and thoughts that can be changed. CBT-I targets exactly these patterns.
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "Which of these patterns do you recognize in yourself?",
                        placeholder: "Be honest with yourself here..."
                    )
                )
            ],
            requiredConditions: []
        ),

        // WEEK 1 — Sleep Diary intro
        WorkbookModule(
            id: "w1_sleep_diary",
            week: 1,
            title: "Your Sleep Diary",
            subtitle: "The foundation of your treatment",
            icon: "book.closed.fill",
            color: "teal",
            sections: [
                ModuleSection(
                    id: "w1sd1",
                    title: "Why Track Your Sleep?",
                    body: """
The sleep diary is the cornerstone of CBT-I. It serves three purposes:

1. **Baseline** — reveals your actual sleep patterns, which are often different from what you estimate
2. **Treatment guide** — determines your initial sleep window for sleep restriction
3. **Feedback loop** — tracks progress week by week so adjustments can be made

Complete it every morning, as soon as you wake up. Waiting until later introduces memory distortions. Don't use a clock to time yourself during the night — estimate. The goal is subjective experience, not perfect accuracy.
""",
                    exerciseID: nil,
                    reflection: nil
                ),
                ModuleSection(
                    id: "w1sd2",
                    title: "Key Metrics Explained",
                    body: """
**Time In Bed (TIB)** — from when you get into bed to when you get out for the day.

**Sleep Onset Latency (SOL)** — how long it took to fall asleep after lights out.

**Wake After Sleep Onset (WASO)** — total minutes awake during the night (not counting SOL).

**Total Sleep Time (TST)** — TIB minus SOL minus WASO.

**Sleep Efficiency (SE)** — TST ÷ TIB × 100%. The goal of treatment is SE ≥ 85%.

A person with good sleep has high efficiency — most time in bed is spent asleep. Chronic insomnia often produces SE of 60–70% or lower.
""",
                    exerciseID: nil,
                    reflection: nil
                )
            ],
            requiredConditions: []
        ),

        // WEEK 2 — Sleep Restriction
        WorkbookModule(
            id: "w2_sleep_restriction",
            week: 2,
            title: "Sleep Restriction",
            subtitle: "Consolidating sleep by tightening your window",
            icon: "bed.double.fill",
            color: "purple",
            sections: [
                ModuleSection(
                    id: "w2sr1",
                    title: "The Rationale",
                    body: """
Sleep restriction is the most powerful component of CBT-I. The idea is counterintuitive: you temporarily restrict your time in bed to match your actual sleep time.

This does two things:
1. Builds up sleep pressure rapidly — you become genuinely sleepy at bedtime
2. Consolidates fragmented sleep into a solid block

It feels hard in the first week. Mild sleepiness during the day is expected and is a sign it's working. This is not sleep deprivation; you are not sleeping less than your body is producing — you are concentrating it.

**Do not drive or operate heavy machinery if severely sleepy.**
""",
                    exerciseID: nil,
                    reflection: nil
                ),
                ModuleSection(
                    id: "w2sr2",
                    title: "Setting Your Sleep Window",
                    body: """
Your initial sleep window is set based on your average Total Sleep Time from the first week of diary data:

**Initial Time In Bed = Average TST (minimum 5 hours)**

Your prescribed wake time is fixed and non-negotiable — it anchors your circadian rhythm. Your bedtime is calculated by counting backward from your wake time by your allowed TIB.

**Adjusting weekly:**
- SE ≥ 90% → expand window by 15–30 minutes (move bedtime earlier)
- SE 85–89% → keep window the same
- SE < 85% → restrict further by 15 minutes (move bedtime later)

Use the Progress tab to see your SE and the Today tab to review your prescribed window.
""",
                    exerciseID: "sleep_window_calculator",
                    reflection: ReflectionPrompt(
                        question: "What is your biggest concern about restricting your time in bed?",
                        placeholder: "Write your concern here..."
                    )
                )
            ],
            requiredConditions: []
        ),

        // WEEK 2 — Stimulus Control
        WorkbookModule(
            id: "w2_stimulus_control",
            week: 2,
            title: "Stimulus Control",
            subtitle: "Re-training your brain to associate bed with sleep",
            icon: "house.fill",
            color: "orange",
            sections: [
                ModuleSection(
                    id: "w2sc1",
                    title: "How Conditioned Arousal Works",
                    body: """
Through repeated pairing, your brain learns to associate stimuli with states. If you spend hours awake in bed — worrying, scrolling, watching TV — your brain learns: bed = alert, bed = anxious.

This is conditioned arousal. It explains why many people with insomnia feel wide awake the moment they lie down, and sleepy on the couch.

Stimulus control breaks this association by building a new one: bed = sleep.
""",
                    exerciseID: nil,
                    reflection: nil
                ),
                ModuleSection(
                    id: "w2sc2",
                    title: "The Five Rules",
                    body: """
1. **Go to bed only when sleepy** — not just tired, but genuinely drowsy. Sitting in bed waiting to become sleepy deepens the conditioned arousal.

2. **Use the bed only for sleep (and sex)** — no reading, TV, phone, eating, or working in bed.

3. **Get out of bed if you can't sleep** — if you're awake for more than 20 minutes, get up and do something calm in dim light. Return only when sleepy. Repeat as needed.

4. **Set a consistent wake time** — get up at the same time every day, regardless of how much you slept.

5. **Avoid napping** — if you must nap (e.g., safety), limit to 20 minutes before 3 PM.
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "Which of these rules will be hardest for you, and why?",
                        placeholder: "Reflect on your habits..."
                    )
                )
            ],
            requiredConditions: []
        ),

        // WEEK 3 — Sleep Hygiene
        WorkbookModule(
            id: "w3_sleep_hygiene",
            week: 3,
            title: "Sleep Hygiene",
            subtitle: "Habits and environment that support sleep",
            icon: "leaf.fill",
            color: "green",
            sections: [
                ModuleSection(
                    id: "w3sh1",
                    title: "Substances and Sleep",
                    body: """
**Caffeine** has a half-life of 5–7 hours. A 3 PM coffee still has half its caffeine in your system at 9 PM. Cut off caffeine by noon if you're sensitive, or 2 PM at the latest.

**Alcohol** feels like a sleep aid but is a sleep disruptor. It suppresses REM sleep, increases WASO in the second half of the night, and is a bladder irritant. Avoid within 3 hours of bedtime.

**Nicotine** is a stimulant. Smokers have lighter, more fragmented sleep. If you smoke, avoid within 2 hours of bedtime.

**Medications** — some antidepressants, decongestants, corticosteroids, and even sleep aids can disrupt sleep architecture. Discuss with your doctor before changing any medication.
""",
                    exerciseID: nil,
                    reflection: nil
                ),
                ModuleSection(
                    id: "w3sh2",
                    title: "Environment and Habits",
                    body: """
**Temperature** — the ideal sleep environment is cool: 65–68°F (18–20°C). Core body temperature must drop to initiate sleep.

**Light** — darkness signals the pineal gland to release melatonin. Use blackout curtains and avoid bright screens within an hour of bed. Blue-light blocking glasses help if screens are unavoidable.

**Noise** — white noise or earplugs help if you're sensitive. Sudden noises are more disruptive than steady background sound.

**Exercise** — regular aerobic exercise significantly improves sleep quality, but intense exercise within 3–4 hours of bedtime can delay sleep onset for some people.

**Wind-down routine** — a consistent 30–60 minute wind-down routine signals to your brain that sleep is approaching. Keep it calm, dim, and screen-free.
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "What one change to your environment or evening routine could you make this week?",
                        placeholder: "Small, specific change..."
                    )
                )
            ],
            requiredConditions: []
        ),

        // WEEK 4 — Cognitive Restructuring
        WorkbookModule(
            id: "w4_cognitive",
            week: 4,
            title: "Quieting Sleep-Related Worry",
            subtitle: "Changing thoughts that keep you awake",
            icon: "brain.head.profile",
            color: "red",
            sections: [
                ModuleSection(
                    id: "w4cg1",
                    title: "The Role of Thoughts",
                    body: """
What you think about sleep matters. Research shows that people with insomnia hold specific types of unhelpful beliefs that amplify arousal and distress:

- **Catastrophizing** — "If I don't sleep 8 hours, I'll be useless tomorrow"
- **Unrealistic expectations** — "Normal people fall asleep in minutes and never wake up"
- **Attributing everything to bad sleep** — "I made that mistake because I'm sleep-deprived"
- **Helplessness** — "There's nothing I can do. I've always been a bad sleeper"
- **Monitoring and control** — constant mental effort to make yourself sleep (which does the opposite)

These thoughts increase arousal, increase time in bed, and worsen sleep — a self-fulfilling loop.
""",
                    exerciseID: nil,
                    reflection: nil
                ),
                ModuleSection(
                    id: "w4cg2",
                    title: "The Thought Record",
                    body: """
The thought record is a structured technique to examine and reframe unhelpful sleep thoughts. It has four steps:

1. **Identify the thought** — write down the exact thought that's bothering you
2. **Rate your belief** — how much do you believe it? (0–100%)
3. **Examine the evidence** — what supports it? What contradicts it?
4. **Create a balanced thought** — a more accurate, less extreme alternative
5. **Re-rate your belief** — has it shifted?

This is not about positive thinking. It's about accurate thinking. The goal is a realistic appraisal, not forced optimism.

Use the Thought Record exercise in the Practice tab to try this now.
""",
                    exerciseID: "thought_record",
                    reflection: nil
                ),
                ModuleSection(
                    id: "w4cg3",
                    title: "Paradoxical Intention",
                    body: """
One of the most effective techniques for sleep-onset anxiety is paradoxical intention: instead of trying to fall asleep, try to stay awake (with your eyes closed, lying in bed, without doing anything stimulating).

This sounds strange, but the effort to sleep is itself arousing. Removing the effort removes the arousal. Many people find they fall asleep within minutes.

Instructions:
1. Lie down in bed at your prescribed bedtime
2. Close your eyes
3. Gently try to stay awake — don't fight sleep, but don't chase it either
4. If your mind wanders to sleep-related worries, return your attention to staying awake

This reframes the bedroom as a place of passive wakefulness rather than anxious effort.
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "What is your most frequent sleep-related worry? Write it down.",
                        placeholder: "e.g., 'If I don't sleep I won't be able to function at work'"
                    )
                )
            ],
            requiredConditions: []
        ),

        // WEEK 5 — Relaxation
        WorkbookModule(
            id: "w5_relaxation",
            week: 5,
            title: "Relaxation Techniques",
            subtitle: "Calming the body's arousal system",
            icon: "wind",
            color: "cyan",
            sections: [
                ModuleSection(
                    id: "w5r1",
                    title: "Why Relaxation Works",
                    body: """
Insomnia is fundamentally a disorder of hyperarousal — the brain is stuck in a state of heightened alertness. Relaxation techniques work by activating the parasympathetic nervous system (the "rest and digest" system), which is the physiological opposite of the fight-or-flight response.

**What relaxation is not:** a way to force yourself to sleep. Done correctly, it quiets the body so that sleep can emerge naturally.

The techniques covered in the Practice tab — diaphragmatic breathing, progressive muscle relaxation (PMR), and guided imagery — all work differently but aim at the same target: reducing somatic (body-level) arousal.

Consistency matters more than perfection. Practice these techniques during the day, not just at bedtime, so the skill is well-learned before you need it most.
""",
                    exerciseID: "breathing",
                    reflection: nil
                ),
                ModuleSection(
                    id: "w5r2",
                    title: "Progressive Muscle Relaxation",
                    body: """
PMR works by systematically tensing and releasing muscle groups throughout the body. The tension-release cycle creates a contrast that allows muscles to relax more deeply than they would otherwise.

A full PMR session takes 20–30 minutes and covers 16 muscle groups. An abbreviated version covers 8 groups in 10–15 minutes.

**Key principles:**
- Tense each group for 5–7 seconds (not so hard it cramps)
- Release and notice the difference for 20–30 seconds
- Move progressively from feet to face (or face to feet)
- Keep the rest of the body relaxed while tensing a single group

Use the PMR exercise in the Practice tab for a guided session.
""",
                    exerciseID: "pmr",
                    reflection: nil
                )
            ],
            requiredConditions: []
        ),

        // Depression-specific
        WorkbookModule(
            id: "w6_depression",
            week: 6,
            title: "Sleep and Depression",
            subtitle: "Specific strategies for low mood",
            icon: "cloud.rain.fill",
            color: "blue",
            sections: [
                ModuleSection(
                    id: "w6d1",
                    title: "How Depression Disrupts Sleep",
                    body: """
Depression and insomnia are closely linked — each worsens the other. Depression-related sleep changes include:

- **Early morning awakening** — waking 2–3 hours before desired wake time and being unable to return to sleep
- **Excessive time in bed** — lying in bed as a way to cope with low energy and motivation
- **Hypersomnia** — sleeping too much, especially in the morning, which delays the circadian clock

CBT-I must be adapted for depression:

**Behavioral activation** — staying active and engaged during the day (even when energy is low) is essential. Inactivity deepens both depression and insomnia.

**Getting out of bed at your prescribed wake time even when you slept poorly** is especially important and especially hard when depressed. It is also especially beneficial.

**Rumination at night** — depressive thinking tends to happen at night. The thought record and scheduled worry time are particularly valuable tools.
""",
                    exerciseID: "thought_record",
                    reflection: ReflectionPrompt(
                        question: "When low mood affects your sleep, what typically happens? Do you sleep more or less?",
                        placeholder: "Describe the pattern you notice..."
                    )
                ),
                ModuleSection(
                    id: "w6d2",
                    title: "Behavioral Activation for Sleep",
                    body: """
When depressed, the natural impulse is to withdraw — to stay in bed, cancel plans, reduce activity. This feels protective but actually deepens depression by removing opportunities for positive experience and reinforcement.

Behavioral activation counters this by scheduling activities regardless of how you feel beforehand. The key insight: **mood follows behavior, not the other way around.** You don't wait to feel good before acting; you act and mood improves.

For sleep specifically:
- Get out of bed at your scheduled wake time — do not compensate for a bad night with a later wake time
- Plan at least one absorbing activity in the morning (exercise is ideal)
- Limit time in bed during the day to sleep only
- Build an evening wind-down that includes something genuinely pleasant (not just doom-scrolling)
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "List three activities you find genuinely engaging (even if low-energy). Schedule one for this week.",
                        placeholder: "1. ...\n2. ...\n3. ..."
                    )
                )
            ],
            requiredConditions: [.depression]
        ),

        // Anxiety-specific
        WorkbookModule(
            id: "w6_anxiety",
            week: 6,
            title: "Sleep and Anxiety",
            subtitle: "Specific strategies for worry and hyperarousal",
            icon: "waveform.path.ecg",
            color: "yellow",
            sections: [
                ModuleSection(
                    id: "w6a1",
                    title: "How Anxiety Disrupts Sleep",
                    body: """
Anxiety is a state of physiological and cognitive hyperarousal — exactly the opposite of what sleep requires. Anxiety-related sleep disruptions include:

- **Difficulty falling asleep** — racing thoughts prevent the cognitive quieting needed for sleep onset
- **Middle-of-the-night waking** — the brain is primed to detect threat, so minor stimuli trigger full wakefulness
- **Anticipatory anxiety about sleep** — worrying about whether you'll be able to sleep becomes its own sleep-disrupting loop

The challenge: most anxiety management techniques (reasoning through problems, planning) involve activating the prefrontal cortex — which is the wrong direction when you're trying to sleep.

The goal is to move from cognitive problem-solving mode to a quieter, less evaluative mental state.
""",
                    exerciseID: nil,
                    reflection: nil
                ),
                ModuleSection(
                    id: "w6a2",
                    title: "Scheduled Worry Time",
                    body: """
Worry is not random — it tends to find you at night because that's when you're finally still and undistracted. Scheduled worry time is a technique that moves worry to a designated daytime slot, preventing it from hijacking the sleep period.

**How to do it:**
1. Set a 20-minute worry window each day, at the same time (e.g., 5:00–5:20 PM) — never within 3 hours of bed
2. Keep a worry journal. When worries arise outside this window, write them down and defer them to your worry time
3. During your worry window, actively engage with your worries: think them through, problem-solve what you can, accept what you can't
4. When the 20 minutes are up, close the journal and move on

At bedtime, if a worry surfaces, remind yourself: "I've scheduled time for this. I can set it aside until then."

This works because it gives anxiety what it wants (attention) without letting it steal your sleep.
""",
                    exerciseID: "worry_time",
                    reflection: ReflectionPrompt(
                        question: "What time of day would work for your daily worry window?",
                        placeholder: "e.g., 5:00–5:20 PM after work..."
                    )
                ),
                ModuleSection(
                    id: "w6a3",
                    title: "Somatic Quieting",
                    body: """
Anxiety lives in the body — racing heart, tense muscles, shallow breathing. Somatic quieting techniques address the physical component directly.

**4-7-8 Breathing:**
- Inhale for 4 counts
- Hold for 7 counts
- Exhale slowly for 8 counts
- Repeat 4 cycles

The extended exhale activates the vagus nerve and parasympathetic nervous system. This is not a sleep technique — it's an arousal-reduction technique. Use it when you notice physical anxiety symptoms.

**Body scan:**
Starting at the top of the head, slowly move attention through each part of the body, noticing sensations without judgment. This shifts attention away from cognitive rumination toward non-evaluative body awareness — a gentler form of mindfulness that doesn't require you to "clear your mind."
""",
                    exerciseID: "breathing",
                    reflection: nil
                )
            ],
            requiredConditions: [.anxiety]
        ),

        // MAINTENANCE
        WorkbookModule(
            id: "w8_maintenance",
            week: 8,
            title: "Maintaining Your Gains",
            subtitle: "Building a sustainable sleep life",
            icon: "checkmark.seal.fill",
            color: "mint",
            sections: [
                ModuleSection(
                    id: "w8m1",
                    title: "Handling Setbacks",
                    body: """
Occasional poor nights are normal — even for good sleepers. After completing CBT-I, you will still have bad nights. The difference is how you respond.

**The unhelpful response:** catastrophizing, compensating (sleeping in, napping, going to bed early), and re-entering the insomnia maintenance cycle.

**The helpful response:**
1. Expect bad nights — they are not failures
2. Maintain your wake time regardless
3. Avoid compensating behaviors for one day before considering any schedule change
4. If a run of poor nights returns (3–4 nights in a row), re-apply sleep restriction temporarily

Your sleep window is a tool you now own. You know how to use it.
""",
                    exerciseID: nil,
                    reflection: nil
                ),
                ModuleSection(
                    id: "w8m2",
                    title: "Your Personal Sleep Profile",
                    body: """
By now you know your sleep better than before. Use what you've learned to build your personal sleep profile:

- **Your natural wake time** (when consistent, what time do you naturally wake?)
- **Your sleep window** (how many hours of quality sleep do you need?)
- **Your high-risk factors** (what reliably worsens your sleep? stress, alcohol, irregular schedule?)
- **Your early warning signs** (how does your sleep signal that something is off?)
- **Your response plan** (what's your protocol when sleep degrades?)

A good sleeper is not someone who never has bad nights. A good sleeper is someone who knows how to recover.
""",
                    exerciseID: nil,
                    reflection: ReflectionPrompt(
                        question: "Write your personal sleep profile — what have you learned about yourself?",
                        placeholder: "My natural wake time is...\nI need about... hours...\nStress affects my sleep by..."
                    )
                )
            ],
            requiredConditions: []
        )
    ]

    static func modules(for profile: UserProfile?) -> [WorkbookModule] {
        guard let profile else { return all.filter(\.isUniversal) }
        return all.filter { module in
            if module.isUniversal { return true }
            if module.requiredConditions.contains(.depression) && !profile.hasDepression { return false }
            if module.requiredConditions.contains(.anxiety) && !profile.hasAnxiety { return false }
            if module.requiredConditions.contains(.pain) && !profile.hasPain { return false }
            return true
        }
    }
}

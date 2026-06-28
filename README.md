# QuietMind — CBT-I Insomnia Workbook App

An interactive iOS companion to *Quiet Your Mind and Get to Sleep* by Colleen Carney & Rachel Manber. Built with SwiftUI + SwiftData targeting iOS 17+.

## Setup

### Prerequisites
- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Generate the Xcode project

```bash
cd /path/to/Cbti
xcodegen generate
open QuietMind.xcodeproj
```

Then build and run on a simulator or device (iOS 17+).

---

## App Structure

```
QuietMind/
├── App/
│   ├── QuietMindApp.swift       # App entry point + SwiftData container
│   └── ContentView.swift        # Root tab view / onboarding gate
├── Models/
│   ├── SleepEntry.swift         # @Model: daily sleep diary (SwiftData)
│   ├── UserProfile.swift        # @Model: profile, sleep window, progress
│   └── WorkbookModule.swift     # Workbook content catalog (static)
├── Store/
│   └── AppStore.swift           # ObservableObject: data access + metrics
├── Views/
│   ├── Onboarding/              # 3-page onboarding flow
│   ├── Today/                   # Morning + evening check-in
│   ├── Learn/                   # Module list + detail reader
│   ├── Practice/                # Guided exercises
│   └── Progress/                # Charts (Swift Charts)
└── Utilities/
    ├── NotificationManager.swift
    └── SleepCalculator.swift
```

---

## Features

### Today Tab
- **Prescribed sleep window banner** — shows your current bedtime and wake time
- **Morning log** — bed time, lights-out time, sleep onset latency, WASO, awakenings, quality ratings
- **Evening check-in** — caffeine, alcohol, exercise, naps, pain level, notes
- **Tonight's rules** — stimulus control reminders
- **Auto-calculated metrics** — TST, TIB, sleep efficiency

### Learn Tab
Structured weekly modules covering the full CBT-I protocol:

| Week | Modules |
|------|---------|
| 1 | Understanding Sleep · Sleep Diary |
| 2 | Sleep Restriction · Stimulus Control |
| 3 | Sleep Hygiene |
| 4 | Cognitive Restructuring / Thought Records |
| 5 | Relaxation Techniques |
| 6 | Depression-specific (if selected) · Anxiety-specific (if selected) |
| 7+ | Maintenance |

Each module has:
- Multi-section text content based on the CBT-I framework
- Reflection prompts with text fields
- Links to relevant Practice exercises
- Completion tracking

### Practice Tab
- **Diaphragmatic Breathing** — animated timer with 4-7-8, box, and relaxing patterns
- **Progressive Muscle Relaxation (PMR)** — guided 8-group session with auto-advancing phases
- **Thought Record** — 6-step structured cognitive restructuring exercise
- **Scheduled Worry Time** — worry capture inbox + 20-minute timed worry session with actionability sorting

### Progress Tab (Swift Charts)
- Sleep efficiency line chart with 85% goal line
- Total sleep time bar chart
- Sleep onset latency bar chart
- Sleep window adjustment recommendation based on 7-day SE average

### Notifications
- Morning diary reminder (30 min after wake time, adjustable)
- Evening wind-down reminder (30 min before prescribed bedtime)

---

## Sleep Restriction Protocol

The app follows the standard CBT-I sleep restriction algorithm:

| Sleep Efficiency (7-day avg) | Action |
|------------------------------|--------|
| ≥ 90% | Expand window by 15 min (move bedtime earlier) |
| 85–89% | Keep window the same |
| < 85% | Restrict by 15 min (move bedtime later) |

Minimum time in bed: **5 hours**.

---

## Tech Stack
- SwiftUI (iOS 17+)
- SwiftData (local persistence, no cloud required)
- Swift Charts
- UserNotifications framework

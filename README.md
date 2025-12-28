# TsukiUsagi Timer 🐇
*A poetic Pomodoro timer inspired by the moon — where focus meets quiet rhythm.*

📱 **App Store:**
[Download on the App Store](https://apps.apple.com/jp/app/tsukiusagi-timer/id6753893693)

🌐 **Portfolio Page:**
[tsukiusagi.biz/works/tsukiusagi-timer](https://tsukiusagi.biz/works/tsukiusagi-timer/)

> Built with SwiftUI · ActivityKit

🎨 Designed & developed by [Azu](https://tsukiusagi.biz)
---

## 🌕 Concept

When your focus begins to drift, the calm rhythm of the moon brings it back.
Gaze at the waxing light, breathe with the stars, and return to your center.
TsukiUsagi reminds you: *Stay grounded, yet light.*

---

## 🌙 Features

- Gentle minimalist UI built with SwiftUI
- Animated moon and usagi companion
- Pomodoro-style focus & break rhythm
- Poetic reflections and session tracking
- English & Japanese localization
- Designed for minimalists worldwide

---

## 🏗️ Architecture

Clean Architecture with feature-based organization.

### Entry Point & View Hierarchy

```
TsukiUsagiApp
└── ContentView
    └── TabView
        ├── TimerView (Main Timer)
        │   ├── MoonAnimationView
        │   ├── TimerDisplayView
        │   └── SessionFinishedView (Quiet Moon)
        ├── HistoryView (Session Records)
        │   ├── HistoryListView
        │   └── HistoryDetailView
        └── SettingsView (Preferences)
```

### Core Dependencies (TimerViewModel)

```
TimerViewModel
├── External Dependencies
│   ├── TimerEngineable (timer core)
│   ├── PhaseNotificationServiceable (notifications)
│   ├── HapticServiceable (haptic feedback)
│   ├── SessionHistoryServiceable (history storage)
│   ├── TimerPersistenceManageable (state save)
│   ├── TimeFormatterUtilable (time formatting)
│   ├── DateProviding (date abstraction)
│   └── StreakManager (streak tracking)
│
└── Internal Managers
    ├── TimerAnimationController (animations)
    ├── TimerStatePersistenceManager (state persistence)
    ├── TimerNotificationAndHapticManager (notifications/haptics)
    ├── TimerSessionManager (session lifecycle)
    ├── TimerStateManager (state management)
    ├── TimerDisplayManager (display formatting)
    └── TimerLifecycleCoordinator (app lifecycle)
```

### Data Flow

```
[User Action]
    ↓
TimerViewModel.send(_:) ─────────────────┐
    ↓                                    │
TimerReducer.reduce(state, action)       │
    ↓                                    │
(newState, effects[])                    │
    ↓                                    │
TimerViewModel.executeEffects()          │
    ↓                                    │
[Side Effects] ──────────────────────────┘
  ├── Notifications
  ├── Haptics
  ├── Live Activity
  ├── History Save
  └── State Persistence
```

### Feature Structure

```
TsukiUsagi/
├── Entry/
│   └── TsukiUsagiApp.swift
├── Foundation/
│   ├── DesignTokens.swift
│   ├── Protocols/
│   └── Managers/
└── Features/
    ├── Timer/
    │   ├── Views/
    │   ├── ViewModels/
    │   ├── Managers/
    │   └── Models/
    ├── History/
    │   ├── Views/
    │   ├── ViewModels/
    │   └── Models/
    ├── Settings/
    │   └── Views/
    ├── Streak/
    │   └── Views/
    └── Common/
        └── Components/
```

### Persistence Layer

| Type | Storage | Purpose |
|------|---------|---------|
| UserDefaults | `@AppStorage` | Settings (work/break minutes, labels) |
| File-based | `Documents/history.json` | Session history |
| Memory | `@Published` | Runtime state |

---

## 🌸 Story

**Born from a moment I almost cried.**
In that quiet pause, TsukiUsagi was born —
to turn stillness into rhythm, and rhythm into focus.

---

## 🔒 Privacy Policy
- [Privacy Policy (English / 日本語)](https://azu-azu.github.io/tsukiusagi-timer/privacy.html)

---

## ⚖️ License
MIT License
Copyright © 2025 TsukiUsagi

---

### ✨ App Store
- v1.0.0 2025/10/15
- v1.1.0 2025/10/21 - Design tweaks
- v1.2.0 2025/11/02 - Live Activity support
- v1.2.1 2025/11/08 - Bug fixes (Timer display, Animation, Live Activity)
- v1.3.0 2025/12/08 - UI refresh with TsukiSound-style cards, chat-style Reflection input, emoji prefixes for sessions/tasks

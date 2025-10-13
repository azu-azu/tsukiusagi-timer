## CLAUDE.md - AI Assistant Guide
# Version: 1.0 (Synced with ENGINEERING_RULES.md v1.0)
# Last Updated: 2025-10-13

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**TsukiUsagi** is a SwiftUI-based Pomodoro timer app with a minimalist, moon-themed design. The architecture follows Clean Architecture principles with feature-based organization.

### Key Components

- **Entry Point**: `TsukiUsagi/Entry/TsukiUsagiApp.swift`
- **Design System**: `TsukiUsagi/Foundation/DesignTokens.swift` - Centralized design tokens
- **Session Management**: `TsukiUsagi/Foundation/Managers/SessionManager.swift` - Core session data management

### Architecture (See Core: ARCH-01, ARCH-02)

**Clean Architecture** with unidirectional dependencies:
- UI → Application(UseCases) → Domain
- Domain layer has no external dependencies
- All external elements abstracted via Protocols

**Feature Organization** (See Core: STRUCT-01):
```
TsukiUsagi/Features/
├── Timer/          # Core Pomodoro timer functionality
├── Settings/       # Session configuration and preferences
├── History/        # Session history tracking
└── Common/         # Shared feature components
```

---

## Development Commands (See Core: BUILD-01)

Build and test commands are defined in `ENGINEERING_RULES.md` BUILD-01 section.

---

## AI Assistant Guidelines

### How to Ask the Assistant

**For Code Review**:
- "Review this code for Clean Architecture compliance" (See Core: ARCH-01, ARCH-02)
- "Check if this follows the 3-layer text classification system" (See Core: TXT-01)
- "Verify this uses DesignTokens instead of direct font/color specs" (See Core: UI-01)

**For Implementation**:
- "Implement this feature following Clean Architecture principles" (See Core: ARCH-01, ARCH-02)
- "Create a new session management feature with proper validation" (See Core: QUALITY-01)
- "Add error handling with user-friendly messages" (See Core: QUALITY-01)

**For Debugging**:
- "Help debug this FocusState issue" (See Core: UI-02)
- "Fix this ScrollView layout problem" (See Core: UI-02)
- "Resolve this EnvironmentObject injection error" (See Core: QUALITY-01)

### Code Generation Patterns

**ViewModel Pattern** (See Core: ARCH-02):
```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    private let useCase: SomeUseCase

    init(useCase: SomeUseCase) {
        self.useCase = useCase
    }

    func performAction() {
        Task {
            try? await useCase()
        }
    }
}
```

**View Pattern** (See Core: UI-01, UI-02):
```swift
struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel

    var body: some View {
        // UI implementation using DesignTokens
    }
}
```

---

## Private Commands (See Core: TOOL-01)

### log.n
Generate log file names for issue tracking.

**Format**: `<YYYY-MM-DD>_log_title_in_snake_case.md`

**Usage**: "Generate `log.n` with format for focus state keyboard sync issue"


---

## Reference Links

- **Core Rules**: `ENGINEERING_RULES.md` (Single Source of Truth)
- **Structure Guidelines**: `/docs/structure-guidelines.md`
- **Lint Exceptions**: `/docs/lint_exceptions.md`
- **Copy Classification Guide**: `/docs/_guide-copy-classification.md`

---

## Version Sync

This file is synchronized with `ENGINEERING_RULES.md v1.0`. When core rules are updated, this file should be updated to reference the new version and any changed policy IDs.

---

## Core Rules Quick Reference

For detailed implementation guidelines, see the following sections in `ENGINEERING_RULES.md`:

- **ARCH-01, ARCH-02**: Architecture principles and Clean Architecture implementation
- **UI-01**: Design system usage (DesignTokens)
- **UI-02**: SwiftUI best practices (onChange, FocusState, ScrollView)
- **TXT-01, TXT-02**: Text classification system and localization rules
- **BUILD-01**: Build and test standards (iPhone 16 simulator)
- **TOOL-01**: Private commands (log.n)
- **LOG-01**: Logging standards
- **STRUCT-01**: File organization (feature-based)
- **QUALITY-01**: Code quality standards and error handling
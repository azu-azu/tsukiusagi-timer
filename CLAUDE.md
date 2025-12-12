## CLAUDE.md - AI Assistant Guide
# Version: 2.0 (Synced with ENGINEERING_RULES.md Supervised Engineering Edition)
# Last Updated: 2025-11-01

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**TsukiUsagi** is a SwiftUI-based Pomodoro timer app with a minimalist, moon-themed design. The architecture follows Clean Architecture principles with feature-based organization.

### Key Components

- **Entry Point**: `TsukiUsagi/Entry/TsukiUsagiApp.swift`
- **Design System**: `TsukiUsagi/Foundation/DesignTokens.swift` - Centralized design tokens
- **Session Management**: `TsukiUsagi/Foundation/Managers/SessionManager.swift` - Core session data management

### Architecture (See: arch-01, arch-02)

**Clean Architecture** with unidirectional dependencies:
- UI → Application(UseCases) → Domain
- Domain layer has no external dependencies
- All external elements abstracted via Protocols

**Feature Organization** (See: struct-01):
```
TsukiUsagi/Features/
├── Timer/          # Core Pomodoro timer functionality
├── Settings/       # Session configuration and preferences
├── History/        # Session history tracking
└── Common/         # Shared feature components
```

---

## Development Commands (See: build-01)

Build and test commands are defined in `ENGINEERING_RULES.md` build-01 section.

---

## AI Assistant Guidelines

### How to Ask the Assistant

**For Code Review**:
- "Review this code for Clean Architecture compliance" (See: arch-01, arch-02)
- "Check if this follows the 3-layer text classification system" (See: text-01)
- "Verify this uses DesignTokens instead of direct font/color specs" (See: ui-01)

**For Implementation**:
- "Implement this feature following Clean Architecture principles" (See: arch-01, arch-02)
- "Create a new session management feature with proper validation" (See: quality-01)
- "Add error handling with user-friendly messages" (See: quality-01)

**For Debugging**:
- "Help debug this FocusState issue" (See: ui-02)
- "Fix this ScrollView layout problem" (See: ui-02)
- "Resolve this EnvironmentObject injection error" (See: quality-01)

### Code Generation Patterns

**ViewModel Pattern** (See: arch-02):
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

**View Pattern** (See: ui-01, ui-02):
```swift
struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel

    var body: some View {
        // UI implementation using DesignTokens
    }
}
```

---

## Private Commands

### /fn (log filename generator)
Generate log file names for issue tracking.

**Format**: `<YYYY-MM-DD>_log_title_in_snake_case.md`

**Usage**: "Generate log filename for focus state keyboard sync issue"


---

## Reference Links

- **Core Rules**: `ENGINEERING_RULES.md` (Single Source of Truth)
- **Structure Guidelines**: `/TsukiUsagi/Docs/structure-guidelines.md`
- **Lint Exceptions**: `/TsukiUsagi/Docs/lint-exceptions.md`
- **Copy Classification Guide**: `/TsukiUsagi/Docs/implementation/_guide-copy-classification.md`

---

## Version Sync

This file is synchronized with `ENGINEERING_RULES.md` (Supervised Engineering Edition). When core rules are updated, this file should be updated to reference the new version and any changed policy IDs.

---

## Core Rules Quick Reference

For detailed implementation guidelines, see the following sections in `ENGINEERING_RULES.md`:

**Philosophy & Process:**
- Philosophy: Core beliefs and simplicity principles
- Process: Planning, implementation flow, and "3 attempts" rule

**Project-Specific Technical Rules:**
- **arch-01**: Architecture principles and Clean Architecture implementation
- **arch-02**: Clean Architecture layer structure and checklist
- **ui-01**: Design system usage (DesignTokens)
- **ui-02**: SwiftUI best practices (onChange, FocusState, ScrollView)
- **text-01**: Text classification system (Labels/Copy/Messages)
- **text-02**: Localization rules
- **build-01**: Build and test standards (iPhone 16 simulator)
- **struct-01**: File organization (feature-based)
- **quality-01**: Code quality standards and error handling

**Quality & Governance:**
- Quality Gates: Definition of Done, test guidelines
- Observability & Governance: Traceability, AI collaboration boundaries, metrics
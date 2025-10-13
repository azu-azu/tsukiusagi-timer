## Engineering Rules v1.0 • 2025-10-13

This document serves as the Single Source of Truth for all engineering standards and practices in the TsukiUsagi project.

## Table of Contents

- [ARCH-01: Architecture Principles](#arch-01-architecture-principles)
- [ARCH-02: Clean Architecture Implementation](#arch-02-clean-architecture-implementation)
- [UI-01: Design System Usage](#ui-01-design-system-usage)
- [UI-02: SwiftUI Best Practices](#ui-02-swiftui-best-practices)
- [TXT-01: Text Classification System](#txt-01-text-classification-system)
- [TXT-02: Localization Rules](#txt-02-localization-rules)
- [BUILD-01: Build and Test Standards](#build-01-build-and-test-standards)
- [TOOL-01: Private Commands](#tool-01-private-commands)
- [LOG-01: Logging Standards](#log-01-logging-standards)
- [STRUCT-01: File Organization](#struct-01-file-organization)
- [QUALITY-01: Code Quality Standards](#quality-01-code-quality-standards)

---

## ARCH-01: Architecture Principles

**Policy ID**: ARCH-01
**Last Updated**: 2025-10-13

### Core Principles (Non-Negotiable)

- **Clean Architecture / Clean Code** as the foundation
- **Unidirectional dependency**: UI → Application(UseCases) → Domain
- **Domain layer must not depend on anything**
- **All external elements** (notifications, DB, files, Clock, UUID, Haptics) must be **abstracted via Protocols** and injected via DI
- **Single Responsibility Principle (SRP)**: Methods/types should be small, clear, with limited side effects
- **Early returns preferred**, shallow nesting
- **Intent-revealing names**: Focus on "why + outcome" rather than "what"

### SwiftUI Application Guidelines

- **View**: Only rendering and input handling. Business logic goes to ViewModel/UseCase
- **ViewModel**: State management and UseCase invocation only. **No direct calls** to date/notifications/storage
- **UseCase**: 1 UseCase = 1 file/1 type. Async via `async`/`await`, side effects via injected Gateways
- **Domain**: Pure types. No direct `Date.now` usage (use Clock abstraction)
- **Flow**: Screen events → ViewModel → UseCase → Domain → (via Gateway) external world

---

## ARCH-02: Clean Architecture Implementation

**Policy ID**: ARCH-02
**Last Updated**: 2025-10-13

### Layer Structure

```
Domain/
  Entities/, ValueObjects/, DomainServices/
Application/
  UseCases/ (FooUseCase.swift)
  Ports/ (Protocols: NotificationGateway, Clock, Storage ...)
InterfaceAdapters/
  Gateways/ (NotificationGatewayImpl, StorageImpl ...)
  Mappers/
Presentation/
  Views/, ViewModels/
Infrastructure/
  Concrete/ (UserDefaultsStorage, UNUserNotificationCenterAdapter ...)
```

### Review Checklist

- [ ] Dependency direction is UI→App→Domain unidirectional? (No reverse dependencies)
- [ ] External access (notifications/time/storage/UUID) via Protocol? Testable with mocks?
- [ ] UseCase has single responsibility? Name follows "verb+object" pattern (`ScheduleSessionEnd`)?
- [ ] No direct UseCase calls from View? (Must go through ViewModel)
- [ ] Names reveal intent? No processing that requires comments to understand?
- [ ] Exceptions/failures not swallowed? (Use Result/throws)
- [ ] Tests exist for Domain/UseCase? (UI snapshots optional)

### Implementation Example

```swift
// Domain
struct Session: Equatable { /* Pure type, invariants guaranteed in init */ }
protocol Clock { var now: Date { get } }

// Application (UseCase)
protocol ScheduleSessionEnd {
    func callAsFunction(_ session: Session) async throws
}

// Port
protocol NotificationGateway {
    func scheduleEnd(for session: Session, at date: Date) async throws
}

// InterfaceAdapters
struct SystemClock: Clock { var now: Date { Date() } }
struct NotificationGatewayImpl: NotificationGateway { /* Contains UNUserNotificationCenter */ }

// Presentation (VM)
@MainActor
final class TimerViewModel: ObservableObject {
    private let scheduleSessionEnd: ScheduleSessionEnd
    init(scheduleSessionEnd: ScheduleSessionEnd) { self.scheduleSessionEnd = scheduleSessionEnd }
    func didTapStart(session: Session) {
        Task { try? await scheduleSessionEnd(session) }
    }
}
```

---

## UI-01: Design System Usage

**Policy ID**: UI-01
**Last Updated**: 2025-10-13

### Mandatory Rules

- **Always use semantic tokens** from `DesignTokens.swift` instead of direct font/color values
- **Font usage**: Use `DesignTokens.Fonts.label`, `.labelBold`, `.title`, etc.
- **Color usage**: Use `DesignTokens.MoonColors.textPrimary`, `.textSecondary`, etc.
- **Never use direct font specifications** like `.font(.system(size: 17))` - this will fail lint checks

### Design Token Categories

- **Fonts**: `DesignTokens.Fonts.*`
- **Colors**: `DesignTokens.MoonColors.*`
- **Spacing**: `DesignTokens.Spacing.*`
- **Corner Radius**: `DesignTokens.CornerRadius.*`

---

## UI-02: SwiftUI Best Practices

**Policy ID**: UI-02
**Last Updated**: 2025-10-13

### iOS 17+ onChange Syntax

**MANDATORY**: Use 2-argument closure format:

```swift
// ✅ Correct (iOS 17+)
.onChange(of: value) { oldValue, newValue in
    // Handle change here
}

// ❌ Incorrect (iOS 17+)
.onChange(of: value) { newValue in ... }
```

### FocusState vs Binding Rules

#### Rule #1: focused() requires FocusState.Binding only

```swift
TextField(...).focused($isActivityFocused)
// $isActivityFocused is FocusState<Bool>.Binding, NOT Binding<Bool>
```

#### Rule #2: ViewModifier uses regular Binding<Bool>

```swift
struct SomeModifier: ViewModifier {
    @Binding var isFoo: Bool  // Regular Binding<Bool>
}

// If FocusState needed, change modifier type:
struct DismissKeyboardOnTap: ViewModifier {
    var isActivityFocused: FocusState<Bool>.Binding
}
```

#### Rule #3: State for UI switching

```swift
// ❌ Computed properties don't trigger View redraw
private var isCustomActivity: Bool { ... }

// ✅ Use @State for UI switching
@State var isCustomActivity: Bool
```

### ScrollView Implementation

**MANDATORY**: Put actual content inside ScrollView:

```swift
// ❌ Wrong - empty ScrollView
ScrollView {
    Color.clear.frame(height: 300)
}

// ❌ Wrong - content outside ScrollView
ZStack {
    ScrollView { Color.clear }
    Text("Actual text") // Won't scroll
}

// ✅ Correct - content inside ScrollView
ScrollView(.vertical, showsIndicators: false) {
    Text("Actual text")
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
}
.frame(height: 300)
```

### Landscape Handling

```swift
@Environment(\.horizontalSizeClass) private var horizontalClass
@Environment(\.verticalSizeClass) private var verticalClass

private func safeIsLandscape(size: CGSize) -> Bool {
    return horizontalClass == .regular || size.width > size.height
}
```

### SafeArea and Notch Avoidance

```swift
// Landscape notch avoidance
private var leftPadding: CGFloat {
    if isLandscape {
        return max(24, safeAreaInsets.leading + 20)
    } else {
        return 24
    }
}

// Portrait notch avoidance
private var topPadding: CGFloat {
    return max(paddingY, safeAreaInsets.top + deviceSpecificPadding)
}
```

---

## TXT-01: Text Classification System

**Policy ID**: TXT-01
**Last Updated**: 2025-10-13

### 3-Layer Classification (MANDATORY for new code)

**Labels.swift**: Name tags (headings, item names, status names)
**Copy.swift**: Microcopy (buttons, tabs, links)
**Messages.swift**: Contextual messages (placeholders, descriptions, alerts)

### Classification Rules

- **Labels**: End with `:` (section prefixes), status names, item names
- **Copy**: Action verbs (OK/Save/Delete/Retry), buttons, links
- **Messages**: Contain `? . ! …`, over 40 characters, placeholders, descriptions

### Boundary Rules

- Contains `? . ! …` → Messages
- Ends with `:` (line prefix) → Labels
- Action verbs (OK/Save/Delete/Retry) → Copy
- Over 40 characters → Messages

### Implementation Examples

```swift
// ❌ Forbidden
Text(NSLocalizedString("session_management_title", comment: ""))

// ✅ Correct
Text(Labels.Sections.sessionManagement)
Button(Copy.Button.save) { }
Text(Messages.Placeholders.sessionName)
```

### Exceptions

- Legacy code migration: `NSLocalizedString` direct calls allowed during transition
- New features/new files: Must use 3-layer classification

---

## TXT-02: Localization Rules

**Policy ID**: TXT-02
**Last Updated**: 2025-10-13

### Prohibited Patterns

- **Direct `NSLocalizedString` calls** in new code
- **Hardcoded strings** in UI components
- **Mixed language** in same component

### Required Patterns

- **Use 3-layer classification** (TXT-01)
- **Semantic naming** for localization keys
- **Contextual comments** for translators

---

## BUILD-01: Build and Test Standards

**Policy ID**: BUILD-01
**Last Updated**: 2025-10-13

### Mandatory Simulator

**iPhone 16 simulator ONLY** - other simulators may not be available

### Build Commands

```bash
# Build for iPhone 16 simulator (required)
xcodebuild -project TsukiUsagi.xcodeproj -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project TsukiUsagi.xcodeproj -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### Build Verification

- **Always run build verification** before major changes
- **Test both light and dark mode** appearances
- **Verify on iPhone 16 simulator** only

---

## TOOL-01: Private Commands

**Policy ID**: TOOL-01
**Last Updated**: 2025-10-13

### log.n Command

**Purpose**: Generate log file names for issue tracking

**Format**: `<YYYY-MM-DD>_log_title_in_snake_case.md`

**Examples**:
- `2025-10-13_focus_state_does_not_sync_with_keyboard.md`
- `2025-10-13_session_management_validation_error.md`

**Usage**: Keep concise and descriptive


---

## LOG-01: Logging Standards

**Policy ID**: LOG-01
**Last Updated**: 2025-10-13

### Log File Naming

**Format**: `YYYY-MM-DD_description_in_snake_case`

**Examples**:
- `2025-10-13_build_errors_iphone16_simulator`
- `2025-10-13_focus_state_keyboard_sync_issue`

### Log Directory

**Location**: `logs/` (project root)

### Log Content Structure

```markdown
# Log Title - YYYY-MM-DD

## Issue Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- iOS Version:
- Simulator: iPhone 16
- Xcode Version:

## Resolution
How it was fixed (if applicable)
```

---

## STRUCT-01: File Organization

**Policy ID**: STRUCT-01
**Last Updated**: 2025-10-13

### Feature-Based Organization (MANDATORY)

All features must follow this structure:

```
Features/[FeatureName]/
├── Components/     # UI components and view modifiers
├── Models/         # Data models and entities
├── Services/       # Business logic, external integrations, data management
├── ViewModels/     # Presentation layer logic
├── Views/          # UI screen definitions
└── Utilities/      # Feature-specific utilities
```

### Naming Conventions (STRICTLY ENFORCED)

- **Directory names**: Complete words (`Utilities`, not `Utils`)
- **Pluralization**: Directories with multiple items use plural form (`Moons/`, `Stars/`, `Usagis/`)
- **Manager vs Store**:
  - **Manager**: System resource management, lifecycle management, external API coordination
  - **Store**: Application state persistence, data storage, state change notifications

### File Placement Rules

- **Visual components**: `Visual/[Category]/`
- **Reusable UI components**: `Components/[Category]/`
- **Business logic**: `Services/`
- **Time formatting**: `Foundation/Formatters/`

### Compliance Requirements

- **Pre-implementation check**: Verify file placement follows structure guidelines
- **No exceptions**: Structure violations will be rejected
- **Reference document**: Always consult `/docs/structure-guidelines.md`

---

## QUALITY-01: Code Quality Standards

**Policy ID**: QUALITY-01
**Last Updated**: 2025-10-13

### Lint Exception Management

- **Issue numbers required** for all suppressions
- **Reasons and target dates** must be documented
- **All suppressions** must be documented in `/docs/lint_exceptions.md`
- **Format**: `// swiftlint:disable:next rule_name // Issue #123: Reason (YYYY-MM target)`

### Environment Object Injection

- **Ensure `SessionManager`** is injected into all relevant views
- **Missing injection causes crashes** - particularly important for Settings views and previews
- **Test all previews** with proper environment objects

### Session Management

- **Use `SessionManager`** for all session-related CRUD operations
- **Session names**: 30-character limit
- **Descriptions**: 50-character limit
- **Default sessions** ("Work", "Study", "Read") cannot be deleted
- **All operations** include validation through `SessionManagerValidator`

### Error Handling

- **User input validation** (duplicates, required, limits) in ViewModel
- **Immediate error feedback** in UI
- **Use try/catch** for error handling
- **Display errors** via alerts to users

### Implementation Approach

- **Incremental implementation** - small units, verify, get user confirmation
- **Specification changes** and bug fixes are easier with this approach
- **Reduces miscommunication** and rework

---

## Version History

- **v1.0** (2025-10-13): Initial version with core rules consolidation

---

## References

- **Structure Guidelines**: `/docs/structure-guidelines.md`
- **Lint Exceptions**: `/docs/lint_exceptions.md`
- **Copy Classification Guide**: `/docs/_guide-copy-classification.md`
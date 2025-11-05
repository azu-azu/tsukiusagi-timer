# Development Guidelines (Supervised Engineering Edition)

## Philosophy

### Core Beliefs

* **Incremental progress over big bangs** – Prefer many small, safe merges.
* **Learning from existing code** – Observe before acting; patterns reveal intent.
* **Pragmatic over dogmatic** – Adapt principles to context, not context to principles.
* **Clear intent over clever code** – Readability is the highest form of elegance.
* **Human-guided over auto-generated** – AI is a tool, not a decision maker.

### Simplicity Means

* Single responsibility per function/class
* Avoid premature abstractions
* No clever tricks — prefer boring correctness
* If it requires explaining, it probably needs refactoring

---

## Process

### 1. Planning & Staging

Break complex work into 3–5 verifiable stages, and record in `IMPLEMENTATION_PLAN.md`:

```markdown
## Stage N: [Name]
**Goal**: [Specific deliverable]
**Success Criteria**: [Testable outcomes]
**Tests**: [Specific test cases]
**Status**: [Not Started | In Progress | Complete]
**AI Involvement**: [None | Partial | Generated]
```

* Update status as you progress
* Explicitly note which steps involve AI tools
* Remove file once all stages are complete and reviewed

---

### 2. Implementation Flow

1. **Understand** – Study existing patterns and constraints
2. **Test** – Write a failing test first (red)
3. **Implement** – Write minimal passing code (green)
4. **Refactor** – Clean and align with project conventions
5. **Commit** – Reference related plan stage and intent

---

### 3. When Stuck (After 3 Attempts)

**Critical rule:** Stop after 3 failed attempts.

1. **Document failures**

   * What was tried
   * Exact error or test output
   * Hypothesis of failure cause
2. **Research 2–3 external examples**
3. **Question abstraction level**

   * Is this too general / too granular?
4. **Reframe the problem**

   * Try removing complexity, not adding it
5. **Record insight in `LESSONS_LEARNED.md`**

---

## Project-Specific Technical Rules

### arch-01: Architecture Principles

**Last Updated**: 2025-10-13

#### Core Principles (Non-Negotiable)

- **Clean Architecture / Clean Code** as the foundation
- **Unidirectional dependency**: UI → Application(UseCases) → Domain
- **Domain layer must not depend on anything**
- **All external elements** (notifications, DB, files, Clock, UUID, Haptics) must be **abstracted via Protocols** and injected via DI
- **Single Responsibility Principle (SRP)**: Methods/types should be small, clear, with limited side effects
- **Early returns preferred**, shallow nesting
- **Intent-revealing names**: Focus on "why + outcome" rather than "what"

#### SwiftUI Application Guidelines

- **View**: Only rendering and input handling. Business logic goes to ViewModel/UseCase
- **ViewModel**: State management and UseCase invocation only. **No direct calls** to date/notifications/storage
- **UseCase**: 1 UseCase = 1 file/1 type. Async via `async`/`await`, side effects via injected Gateways
- **Domain**: Pure types. No direct `Date.now` usage (use Clock abstraction)
- **Flow**: Screen events → ViewModel → UseCase → Domain → (via Gateway) external world

---

### arch-02: Clean Architecture Implementation

**Last Updated**: 2025-10-13

#### Layer Structure

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

#### Review Checklist

- [ ] Dependency direction is UI→App→Domain unidirectional? (No reverse dependencies)
- [ ] External access (notifications/time/storage/UUID) via Protocol? Testable with mocks?
- [ ] UseCase has single responsibility? Name follows "verb+object" pattern (`ScheduleSessionEnd`)?
- [ ] No direct UseCase calls from View? (Must go through ViewModel)
- [ ] Names reveal intent? No processing that requires comments to understand?
- [ ] Exceptions/failures not swallowed? (Use Result/throws)
- [ ] Tests exist for Domain/UseCase? (UI snapshots optional)

#### Implementation Example

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

### ui-01: Design System Usage

**Last Updated**: 2025-10-13

#### Mandatory Rules

- **Always use semantic tokens** from `DesignTokens.swift` instead of direct font/color values
- **Font usage**: Use `DesignTokens.Fonts.label`, `.labelBold`, `.title`, etc.
- **Color usage**: Use `DesignTokens.MoonColors.textPrimary`, `.textSecondary`, etc.
- **Never use direct font specifications** like `.font(.system(size: 17))` - this will fail lint checks

#### Design Token Categories

- **Fonts**: `DesignTokens.Fonts.*`
- **Colors**: `DesignTokens.MoonColors.*`
- **Spacing**: `DesignTokens.Spacing.*`
- **Corner Radius**: `DesignTokens.CornerRadius.*`

---

### ui-02: SwiftUI Best Practices

**Last Updated**: 2025-10-13

#### iOS 17+ onChange Syntax

**MANDATORY**: Use 2-argument closure format:

```swift
// ✅ Correct (iOS 17+)
.onChange(of: value) { oldValue, newValue in
    // Handle change here
}

// ❌ Incorrect (iOS 17+)
.onChange(of: value) { newValue in ... }
```

#### FocusState vs Binding Rules

**Rule #1: focused() requires FocusState.Binding only**

```swift
TextField(...).focused($isActivityFocused)
// $isActivityFocused is FocusState<Bool>.Binding, NOT Binding<Bool>
```

**Rule #2: ViewModifier uses regular Binding<Bool>**

```swift
struct SomeModifier: ViewModifier {
    @Binding var isFoo: Bool  // Regular Binding<Bool>
}

// If FocusState needed, change modifier type:
struct DismissKeyboardOnTap: ViewModifier {
    var isActivityFocused: FocusState<Bool>.Binding
}
```

**Rule #3: State for UI switching**

```swift
// ❌ Computed properties don't trigger View redraw
private var isCustomActivity: Bool { ... }

// ✅ Use @State for UI switching
@State var isCustomActivity: Bool
```

#### ScrollView Implementation

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

#### Landscape Handling

```swift
@Environment(\.horizontalSizeClass) private var horizontalClass
@Environment(\.verticalSizeClass) private var verticalClass

private func safeIsLandscape(size: CGSize) -> Bool {
    return horizontalClass == .regular || size.width > size.height
}
```

#### SafeArea and Notch Avoidance

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

### text-01: Text Classification System

**Last Updated**: 2025-10-13

#### 3-Layer Classification (MANDATORY for new code)

**Labels.swift**: Name tags (headings, item names, status names)
**Copy.swift**: Microcopy (buttons, tabs, links)
**Messages.swift**: Contextual messages (placeholders, descriptions, alerts)

#### Classification Rules

- **Labels**: End with `:` (section prefixes), status names, item names
- **Copy**: Action verbs (OK/Save/Delete/Retry), buttons, links
- **Messages**: Contain `? . ! …`, over 40 characters, placeholders, descriptions

#### Boundary Rules

- Contains `? . ! …` → Messages
- Ends with `:` (line prefix) → Labels
- Action verbs (OK/Save/Delete/Retry) → Copy
- Over 40 characters → Messages

#### Implementation Examples

```swift
// ❌ Forbidden
Text(NSLocalizedString("session_management_title", comment: ""))

// ✅ Correct
Text(Labels.Sections.sessionManagement)
Button(Copy.Button.save) { }
Text(Messages.Placeholders.sessionName)
```

#### Exceptions

- Legacy code migration: `NSLocalizedString` direct calls allowed during transition
- New features/new files: Must use 3-layer classification

---

### text-02: Localization Rules

**Last Updated**: 2025-10-13

#### Prohibited Patterns

- **Direct `NSLocalizedString` calls** in new code
- **Hardcoded strings** in UI components
- **Mixed language** in same component

#### Required Patterns

- **Use 3-layer classification** (text-01)
- **Semantic naming** for localization keys
- **Contextual comments** for translators

---

### build-01: Build and Test Standards

**Last Updated**: 2025-10-13

#### Mandatory Simulator

**iPhone 16 simulator ONLY** - other simulators may not be available

#### Build Commands

```bash
# Build for iPhone 16 simulator (required)
xcodebuild -project TsukiUsagi.xcodeproj -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project TsukiUsagi.xcodeproj -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16' test
```

#### Build Verification

- **Always run build verification** before major changes
- **Test both light and dark mode** appearances
- **Verify on iPhone 16 simulator** only

---

### struct-01: File Organization

**Last Updated**: 2025-10-13

#### Feature-Based Organization (MANDATORY)

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

#### Naming Conventions (STRICTLY ENFORCED)

- **Directory names**: Complete words (`Utilities`, not `Utils`)
- **Pluralization**: Directories with multiple items use plural form (`Moons/`, `Stars/`, `Usagis/`)
- **Manager vs Store**:
  - **Manager**: System resource management, lifecycle management, external API coordination
  - **Store**: Application state persistence, data storage, state change notifications

#### File Placement Rules

- **Visual components**: `Visual/[Category]/`
- **Reusable UI components**: `Components/[Category]/`
- **Business logic**: `Services/`
- **Time formatting**: `Foundation/Formatters/`

#### Compliance Requirements

- **Pre-implementation check**: Verify file placement follows structure guidelines
- **No exceptions**: Structure violations will be rejected
- **Reference document**: Always consult `/docs/structure-guidelines.md`

---

### quality-01: Code Quality Standards

**Last Updated**: 2025-10-13

#### Lint Exception Management

- **Issue numbers required** for all suppressions
- **Reasons and target dates** must be documented
- **All suppressions** must be documented in `/docs/lint_exceptions.md`
- **Format**: `// swiftlint:disable:next rule_name // Issue #123: Reason (YYYY-MM target)`

#### Environment Object Injection

- **Ensure `SessionManager`** is injected into all relevant views
- **Missing injection causes crashes** - particularly important for Settings views and previews
- **Test all previews** with proper environment objects

#### Session Management

- **Use `SessionManager`** for all session-related CRUD operations
- **Session names**: 30-character limit
- **Descriptions**: 50-character limit
- **Default sessions** ("Work", "Study", "Read") cannot be deleted
- **All operations** include validation through `SessionManagerValidator`

#### Error Handling

- **User input validation** (duplicates, required, limits) in ViewModel
- **Immediate error feedback** in UI
- **Use try/catch** for error handling
- **Display errors** via alerts to users
- **Log with trace IDs** for observability

#### Implementation Approach

- **Incremental implementation** - small units, verify, get user confirmation
- **Specification changes** and bug fixes are easier with this approach
- **Reduces miscommunication** and rework

---

## Quality Gates

### Definition of Done

* [ ] Tests written and passing
* [ ] Code follows conventions and architecture rules (see project-specific rules)
* [ ] No linter/formatter warnings
* [ ] Commit messages explain *why*, not just *what*
* [ ] Reviewed (human or pair)
* [ ] Observability hooks added if relevant
* [ ] No `TODO` without linked issue ID

---

### Test Guidelines

* Test **behavior**, not implementation details
* One assertion per test when possible
* Descriptive test names ("given-when-then" style)
* Deterministic outputs; avoid external dependency noise
* Use shared mocks/stubs for consistency

---

## Observability & Governance

### Traceability

* Each feature must produce minimal logs or metrics for debugging.
* Key flows (timer, notification, data sync) must include `traceID`.
* Important decisions documented under `/docs/architecture/decisions`.

### AI Collaboration Boundaries

* AI tools may **generate or refactor**, but cannot **merge or approve** without human review.
* All AI edits must appear as isolated commits with clear diff.
* Human must review and sign-off before merging.
* If AI introduces code across multiple layers, perform dependency audit.

### Metrics to Watch

| Metric                     | Goal  | Alert Trigger             |
| -------------------------- | ----- | ------------------------- |
| Build Success Rate         | ≥ 95% | Drop >5%                  |
| Revert Rate                | ≤ 2%  | Revert >3 times per month |
| Test Coverage              | ≥ 80% | Drop >5%                  |
| AI-generated Code Reviewed | 100%  | Any unreviewed commit     |

---

## Important Reminders

**NEVER:**

* Use `--no-verify` to skip checks
* Disable tests instead of fixing them
* Commit code that doesn't compile
* Accept AI changes blindly

**ALWAYS:**

* Commit small, working increments
* Keep documentation aligned with plan
* Use AI to assist, not decide
* Stop after 3 failed attempts and reassess

---

## 🌙 Meta-Note

This guideline defines a **supervised engineering model**:

> *Human judgment + AI acceleration + transparent traceability.*

It's not "AI-driven development."
It's **"human-directed, AI-amplified development."**

---

## Policy ID Quick Reference

| Policy ID  | Topic                           |
| ---------- | ------------------------------- |
| arch-01    | Architecture Principles         |
| arch-02    | Clean Architecture              |
| ui-01      | Design System Usage             |
| ui-02      | SwiftUI Best Practices          |
| text-01    | Text Classification System      |
| text-02    | Localization Rules              |
| build-01   | Build and Test Standards        |
| struct-01  | File Organization               |
| quality-01 | Code Quality Standards          |

---

### Vocabulary（英 | 日）

| English                | 日本語          |
| ---------------------- | ------------ |
| Supervised Engineering | 監督付き開発       |
| Observability          | 可観測性         |
| Traceability           | 追跡可能性        |
| Guardrails             | 安全枠／制御境界     |
| Rollback               | ロールバック（取り消し） |
| Governance             | 統制・運用方針      |
| Reversibility          | 取り返しのつく設計    |

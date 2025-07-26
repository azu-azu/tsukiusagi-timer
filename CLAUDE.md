# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Test
```bash
# Build for iPhone 16 simulator (required - other simulators may not be available)
xcodebuild -project TsukiUsagi.xcodeproj -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project TsukiUsagi.xcodeproj -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### Lint and Code Quality
```bash
# Run SwiftLint (if configured)
swiftlint

# Custom font check script
swift tools/swiftlint_ast_font_check.swift
```

## Architecture Overview

### App Structure
This is a SwiftUI-based Pomodoro timer app with a minimalist, moon-themed design. The architecture follows a feature-based organization with clear separation of concerns.

### Key Architectural Components

**Entry Point**: `TsukiUsagi/Entry/TsukiUsagiApp.swift` - Main app entry
**Design System**: `TsukiUsagi/Foundation/DesignTokens.swift` - Centralized design tokens and semantic color/font definitions
**Session Management**: `TsukiUsagi/Foundation/Managers/SessionManager.swift` - Core session data management with CRUD operations

### Feature Organization
```
TsukiUsagi/Features/
├── Timer/          # Core Pomodoro timer functionality
├── Settings/       # Session configuration and preferences  
├── History/        # Session history tracking
└── Common/         # Shared feature components
```

### Foundation Layer
```
TsukiUsagi/Foundation/
├── DesignTokens.swift      # Design system tokens
├── Managers/               # Data management (SessionManager)
├── Extensions/             # Swift/SwiftUI extensions
├── Controllers/            # Animation and system controllers
└── Utilities/              # Helper functions and formatters
```

### Visual Components
```
TsukiUsagi/Visual/
├── Backgrounds/    # Galaxy and gradient backgrounds
├── Moons/         # Moon shape and animation components
├── Stars/         # Various star animation views
└── Usagis/        # Character animations
```

## Code Structure Guidelines

**CRITICAL: All code changes must follow the structural rules defined in `/docs/structure-guidelines.md`**

### Feature-Based Organization (MANDATORY)
All features must follow this standard structure:
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
- **Directory names**: Use complete words (`Utilities`, not `Utils`)
- **Pluralization**: Directories containing multiple items use plural form (`Moons/`, `Stars/`, `Usagis/`)
- **Manager vs Store distinction**:
  - **Manager**: System resource management, lifecycle management, external API coordination
  - **Store**: Application state persistence, data storage, state change notifications

### File Placement Rules
- **Visual components**: All theme-specific visual elements go in `Visual/[Category]/`
- **Reusable UI components**: Generic, reusable components go in `Components/[Category]/`
- **Business logic**: All business logic, data management, and external services go in `Services/`
- **Time formatting**: All time-related formatting consolidated in `Foundation/Formatters/`

### Compliance Requirements
- **Pre-implementation check**: Verify file placement follows structure guidelines before creating new files
- **No exceptions**: Structure violations will be rejected - restructure to comply with guidelines
- **Reference document**: Always consult `/docs/structure-guidelines.md` for detailed rules and rationale

## Development Guidelines

### Design System Usage
- **Always use semantic tokens** from `DesignTokens.swift` instead of direct font/color values
- Font usage: Use `DesignTokens.Fonts.label`, `.labelBold`, `.title`, etc.
- Color usage: Use `DesignTokens.MoonColors.textPrimary`, `.textSecondary`, etc.
- **Never use direct font specifications** like `.font(.system(size: 17))` - this will fail lint checks

### SwiftUI Best Practices
- **iOS 17+ onChange syntax**: Use 2-argument closure format: `.onChange(of: value) { oldValue, newValue in }`
- **Landscape handling**: Use `@Environment(\.horizontalSizeClass)` for orientation detection
- **FocusState vs Binding**: Use `FocusState.Binding` for `.focused()`, regular `Binding<Bool>` for custom modifiers
- **ScrollView implementation**: Always put actual content inside ScrollView, not as overlay

### Session Management
- Use `SessionManager` for all session-related CRUD operations
- Session names have a 30-character limit, descriptions have 50-item limit
- Default sessions ("Work", "Study", "Read") cannot be deleted
- All session operations include validation through `SessionManagerValidator`

### Lint Exception Management
- Lint suppressions require Issue numbers, reasons, and target dates
- All suppressions must be documented in `/docs/lint_exceptions.md`
- Format: `// swiftlint:disable:next rule_name // Issue #123: Reason (YYYY-MM target)`

### Environment Object Injection
- Ensure `SessionManager` is injected into all relevant views
- Missing injection will cause crashes - particularly important for Settings views and previews

### Testing Requirements
- Always use iPhone 16 simulator for builds and tests
- Run build verification before any major changes
- Test both light and dark mode appearances
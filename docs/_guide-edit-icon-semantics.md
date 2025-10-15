## Edit Icon Semantics and Color Unification Guide

This guide defines the canonical way to render and use the edit (pencil) icon across the app. It centralizes color, separates roles (decorative vs actionable), and enforces accessibility and consistency via lint rules.

### Goals
- **Single source of truth** for edit icon color and semantics
- **Role clarity**: decorative vs actionable vs label+icon
- **Accessibility**: unified labels and 44×44 hit targets
- **Prevent drift**: lint rules to stop raw usages

### Scope
- iOS app UI only (SwiftUI)
- SF Symbol: `pencil`

---

## Design Tokens

- Centralized icon colors live in `DesignTokens.IconColors`.
- Do not pick colors inline for pencil usages.

```swift
// DesignTokens.swift
extension DesignTokens {
    enum IconColors {
        static let pencil = MoonColors.accentBlue
        static let pencilDisabled = MoonColors.textMuted
    }
}
```

Rationale: future changes (palette, themes, HC) can be done in one place.

---

## Components and Their Roles

- **PencilIcon** (decorative)
  - Visual-only, no action; hidden from a11y
  - Always uses `DesignTokens.IconColors.pencil`
  - Use in lists/rows where icon is purely decorative

```swift
// Decorative usage
PencilIcon(size: .small) // a11y hidden; foregroundStyle handled inside
```

- **EditIconButton** (actionable)
  - Tappable, 44×44 hit target, a11y label unified
  - Color via `DesignTokens.IconColors.pencil`
  - Use wherever the pencil triggers edit behavior

```swift
// Actionable usage (starts editing)
EditIconButton(size: .small) {
    // start edit flow
}
```

- **EditIconLabel** (label + icon)
  - For text+icon combinations (e.g., in swipe actions or menus)
  - Uses `Copy.Button.edit` and `DesignTokens.IconColors.pencil`

```swift
// Label with pencil icon and unified copy
EditIconLabel() // defaults to Copy.Button.edit
```

---

## Accessibility Rules

- PencilIcon: `.accessibilityHidden(true)` (handled inside)
- EditIconButton: `.accessibilityLabel(Copy.Button.edit)` (handled inside), 44×44 minimum hit target
- EditIconLabel: uses `Copy.Button.edit` and sets a matching label

Do not hardcode localized strings; always go through the 3-layer system (`Copy/Labels/Messages`).

---

## Do / Don't

- Do: use `PencilIcon` for decoration, `EditIconButton` for actions, `EditIconLabel` for label+icon
- Do: use `DesignTokens.IconColors.pencil` for all pencil coloring (handled inside components)
- Don't: use `NSLocalizedString("edit", ...)` inline (TXT-01 violation)
- Don't: use raw `Image(systemName: "pencil")` or `Label(..., systemImage: "pencil")` directly in feature code

---

## Lint Rules (SwiftLint)

- Error: forbid raw Image pencil

```yaml
custom_rules:
  forbid_raw_pencil_image:
    included: ".swift"
    name: "No raw SF Pencil (Image)"
    regex: 'Image\\(\\s*systemName:\\s*"pencil"\\s*\\)'
    message: "Use EditIconButton or PencilIcon with DesignTokens.IconColors.pencil"
    severity: error
```

- Warning (phase-in): prefer `EditIconLabel` over raw `Label` pencil

```yaml
custom_rules:
  forbid_pencil_label_warning:
    included: ".swift"
    name: "Prefer EditIconLabel over raw Label pencil"
    regex: 'Label\\s*\\([^\\)]*,\\s*systemImage:\\s*"pencil"\\s*\\)'
    message: "Use EditIconLabel for semantic unification"
    severity: warning
```

Escalation plan: after migrating existing usages to `EditIconLabel`, increase severity to `error`.

---

## Migration Guide

1) Replace actionable `Image(systemName: "pencil")` with `EditIconButton { ... }`

```swift
// Before
Image(systemName: "pencil")
    .foregroundColor(DesignTokens.MoonColors.accentBlue)

// After
EditIconButton(size: .small) { onEdit() }
```

2) Replace decorative `Image(systemName: "pencil")` with `PencilIcon(size:)`

```swift
// Before
Image(systemName: "pencil")
    .foregroundColor(DesignTokens.MoonColors.textSecondary)

// After
PencilIcon(size: .small)
```

3) Replace `Label(..., systemImage: "pencil")` with `EditIconLabel()`

```swift
// Before
Label(Copy.Button.edit, systemImage: "pencil")

// After
EditIconLabel()
```

---

## Notes

- Rendering Mode: components use `.symbolRenderingMode(.monochrome)` so color is unified and ready for future palette mode if needed.
- High Contrast: choose tints in `DesignTokens.IconColors` to ensure sufficient contrast; adjust centrally if needed.
- Result Builders: avoid returning `AnyView` from `@ViewBuilder` functions; prefer conditional branches within the builder.

---

## References

- `TsukiUsagi/TsukiUsagi/Foundation/DesignTokens.swift`
- `TsukiUsagi/TsukiUsagi/CrossFeatureUI/Controls/PencilIcon.swift`
- `TsukiUsagi/TsukiUsagi/CrossFeatureUI/Controls/EditIconButton.swift`
- `TsukiUsagi/TsukiUsagi/CrossFeatureUI/Controls/EditIconLabel.swift`
- `.swiftlint.yml`
- ENGINEERING_RULES.md: UI-01 (Design system), TXT-01 (Text classification), UI-02 (SwiftUI best practices)



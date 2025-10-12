# Copy Classification Guide

## Overview

This guide defines the 3-layer classification system for text content in TsukiUsagi app.

## Classification Rules

### 1. Labels.swift = Labels (Name Tags)

**Purpose**: Names, headings, item names, state names (nouns/noun phrases, including colon-terminated row labels)

**Examples**:
- `"Session Management"`
- `"Session Info"`
- `"Reflection"`
- `"Session:"`
- `"Task:"`
- `"No task"`
- `"No records for this day"`

**✅ Allowed**:
- Section headings
- Information row prefixes
- Short state names
- Badge names (`"READ-ONLY"`)

**❌ Not Allowed**:
- Button text (OK/Save/Retry etc.)
- Explanatory text
- Questions
- Long text
- Placeholders

### 2. Copy.swift = Microcopy (Fixed Short Text for UI Elements)

**Purpose**: Fixed short text for UI elements (buttons, tabs, links, toggles, snack bar one/two-word displays, short formats)

**Examples**:
- Button: `Cancel / Save / Close / Reset`
- Tab: `Daily / Monthly`
- Link: `Open Daily Reflection`
- Label: `Time:`, `Total: %@`
- Timer format: `Start 🌕 %@ / Final 🌑 %@`

**✅ Allowed**:
- Reusable short action text
- Fixed format patterns
- UI conventional expressions

**❌ Not Allowed**:
- Screen headings (→ Labels)
- Explanatory text
- Questions
- Variable long text

### 3. Messages.swift = Context Messages

**Purpose**: Explanatory text, alerts, placeholders, toast messages, questions, long state descriptions

**Examples**:
- Explanatory/subtitle: `"Edit tasks for default sessions..."`
- Alert: `"Are you sure you want to delete '%@'?"`
- Placeholder: `"Enter session name"`, `"Select task..."`
- Status text: `"Saved..."`, error titles/content

**✅ Allowed**:
- Sentences
- Questions
- Variable templates
- Placeholders
- Toast messages

**❌ Not Allowed**:
- Name tags (headings/row labels)
- Fixed button text (→ Labels or Copy)

## Boundary Rules (Decision Guards)

- **Punctuation marks `? . ! …` included = Messages** (e.g., `"Delete Session?"` is treated as a message)
- **Colon `:` terminated row prefix = Labels** (e.g., `"Session:"`, `"Time:"`)
- **Verbs themselves (OK/Save/Delete/Retry) = Copy**
- **Screen titles**: If **noun/noun phrase** then Labels (e.g., `"Edit Tasks"` as fixed screen heading → Labels). If you want to change per language in the future, choose **Messages with `localize()`** (unify by design policy)
- **Short state displays** (No XXX yet… etc.): If heading-like then **Labels**, if accompanied by explanation then **Messages**
- **Format strings**: If **short and directly embedded in UI elements** then Copy (`"Total: %@"`, `"Start 🌕 %@"`). Long text templates or sentence construction → **Messages**

## Automatic Checks (Prevent Mistakes)

- **If Labels/Copy contains `? . ! …` → NG** (→ Move to Messages)
- **If Labels item exceeds 40 characters → Warning** (long text = suspected message)
- **If verbs appear outside Buttons/Tab/Link/Timer → Warning** (verbs → Copy/Messages)
- **"No … yet"**: If short heading then **Labels**, if accompanied by explanation then **Messages**

## Important Principles

- **Translation necessity is NOT a classification criterion**
- **All layers (Labels/Copy/Messages) can use NSLocalizedString for localization**
- **Classification is based on content type, not localization method**

## Current Copy.swift Structure

```swift
enum Copy {
    enum Button { /* Cancel/Save/Close/Reset */ }      // ✅ Button text → Copy
    enum Label  { /* Time:, Total:%@, Saved */ }       // ✅ Short labels/fixed formats → Copy
    enum Tab    { /* Daily/Monthly */ }                // ✅ Tab names → Copy
    enum Link   { /* Open Daily Reflection */ }        // ✅ Short link text → Copy
    enum Timer  { /* Start 🌕 %@ / Final 🌑 %@ */ }     // ✅ Short fixed formats → Copy
}
```

## Notes

- `Label.saved = "Saved"` should be **Messages** if used as toast text. If used as badge/status short label (context-free, constant display) then **Copy** is also OK.
- **Decide placement by usage** (whether displayed as "text" or "name tag")

## Automated Guards

### SwiftLint Rules (2 rules)
- `labels_no_sentence`: Prevents sentence-like text (?, !, …, period endings) in Labels.swift
- `copy_no_paragraph`: Prevents long text (>40 chars) in Copy.swift

### Tests
- `LabelsPresenceTests`: Verifies namespace separation (Sections.reflection vs InfoRow.reflection) and content rules with NSLocalizedString comparison
- `MessagesLocalizationSmokeTests`: Verifies message content is properly classified

### Naming Convention
- Labels.State: Use `noRecordsToday` (short, memorable)
- Reflection: Dual namespace (Sections.reflection for headings, InfoRow.reflection for row labels)

### Key Principle
All layers can use NSLocalizedString. Classification is based on content type, not localization method.

Run tests: `xcodebuild test -scheme TsukiUsagi -destination 'platform=iOS Simulator,name=iPhone 16'`


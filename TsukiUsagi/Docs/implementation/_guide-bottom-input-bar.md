# BottomInputBar Usage Guide

## Overview

`BottomInputBar` is a chat-style input component that appears at the bottom of the screen. It requires proper configuration to work correctly.

## Required Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | `Binding<String>` | Yes | Text binding for input |
| `isFocused` | `FocusState<Bool>.Binding` | Yes | Focus state binding |
| `placeholder` | `LocalizedStringKey` | Yes | Placeholder text |
| `onExpand` | `() -> Void` | Yes | Called when expand button tapped |
| `onSubmit` | `(() -> Void)?` | **Recommended** | Called when submit button tapped |

## Common Issue: Submit Button Doesn't Close Input Bar

### Symptom

Pressing the submit (arrow) button updates the text but the input bar remains visible.

### Root Cause

`onSubmit` is optional but **required to close the input bar**. Without it, the component only:
1. Updates the text binding
2. Dismisses keyboard
3. Sets focus to false

It does NOT hide the input bar because that requires setting the parent's state (e.g., `showReflectionInput = false`).

### Solution

Always provide `onSubmit` handler that:
1. Sets focus to false
2. Hides the input bar (set show state to false)
3. Dismisses keyboard

## Correct Usage

```swift
// Parent view state
@State private var showReflectionInput = false
@FocusState private var isReflectionFocused: Bool

// In safeAreaInset
.safeAreaInset(edge: .bottom) {
    if showReflectionInput {
        BottomInputBar(
            text: $reflectionText,
            isFocused: $isReflectionFocused,
            placeholder: LocalizedStringKey("reflection_placeholder"),
            onExpand: {
                isReflectionFocused = false
                showReflectionInput = false
                showSheet = true
            },
            onSubmit: {  // <- Don't forget this!
                isReflectionFocused = false
                showReflectionInput = false
                Keyboard.dismiss()
            }
        )
    }
}
```

## Incorrect Usage (Bug)

```swift
// Missing onSubmit - submit button won't close the bar!
BottomInputBar(
    text: $reflectionText,
    isFocused: $isReflectionFocused,
    placeholder: LocalizedStringKey("reflection_placeholder"),
    onExpand: { ... }
    // onSubmit is missing!
)
```

## Affected Files (Historical)

| Date | File | Issue | Fix |
|------|------|-------|-----|
| 2025-12-17 | EditRecordView.swift | Submit button didn't close input bar | Added onSubmit handler |

## Related

- `BottomInputBar.swift` - Component implementation
- `ReflectionInputSection.swift` - Common reflection input section

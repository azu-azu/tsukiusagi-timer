# BottomInputBar Usage Guide

## Overview

`BottomInputBar` is a chat-style input component that appears at the bottom of the screen. It has specific internal state management that requires careful handling in parent views.

## CRITICAL: Dual-Screen Consistency

`BottomInputBar` is used in TWO screens that MUST behave identically:

| Screen | File | Purpose |
|--------|------|---------|
| **History (View Details)** | `DailyTimelineView.swift` | Daily reflection editing |
| **Edit Record** | `EditRecordView.swift` | Post-session memo editing |

**WARNING**: When modifying BottomInputBar behavior in one screen, you MUST verify the other screen still works correctly. Both screens share:
- `ReflectionInputSection` component
- `BottomInputBar` component
- Same UX expectations (tap to open, submit to save, background tap to dismiss keyboard only)

---

## Architecture: Internal State Pattern

### Key Design Decision

`BottomInputBar` maintains an **internal editing state** (`editingText`) that is separate from the parent's binding (`text`). The parent binding is ONLY updated when:

1. **Submit button is pressed** (`handleSubmit()`)
2. **Expand button is pressed** (`handleExpand()`)

```
┌─────────────────────────────────────────────────────┐
│ BottomInputBar                                      │
│                                                     │
│   @Binding var text: String     ← External binding  │
│   @State private var editingText: String  ← Internal│
│                                                     │
│   onAppear: editingText = text                      │
│   handleSubmit: text = editingText → onSubmit()     │
│   handleExpand: text = editingText → onExpand()     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Consequence

If the input bar disappears (e.g., `showReflectionInput = false`) WITHOUT calling `handleSubmit()` or `handleExpand()`, **the internal `editingText` is lost**.

---

## Required Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | `Binding<String>` | Yes | Text binding for input |
| `isFocused` | `FocusState<Bool>.Binding` | Yes | Focus state binding |
| `placeholder` | `LocalizedStringKey` | Yes | Placeholder text |
| `onExpand` | `() -> Void` | Yes | Called when expand button tapped |
| `onSubmit` | `(() -> Void)?` | **Required** | Called when submit button tapped |

---

## Common Issues and Solutions

### Issue 1: Submit Button Doesn't Close Input Bar

**Symptom**: Pressing the submit (arrow) button updates the text but the input bar remains visible.

**Root Cause**: `onSubmit` is technically optional but **functionally required**. Without it, the component only:
1. Updates the text binding
2. Dismisses keyboard
3. Sets focus to false

It does NOT hide the input bar because that requires setting the parent's state.

**Solution**: Always provide `onSubmit` handler.

```swift
onSubmit: {
    isReflectionFocused = false
    showReflectionInput = false
    Keyboard.dismiss()
}
```

---

### Issue 2: Background Tap Closes Input Bar AND Loses Text

**Symptom**: Tapping outside the input bar while editing causes:
1. Input bar to disappear
2. All typed text to be lost

**Root Cause**: Using `.dismissKeyboardOnTap { closeKeyboard() }` where `closeKeyboard()` sets `showReflectionInput = false`. This:
1. Hides the input bar immediately
2. Destroys the internal `editingText` state
3. Never calls `handleSubmit()` to save to the external binding

**Solution**: Use a custom `onTapGesture` that only dismisses the keyboard, NOT the input bar.

```swift
// CORRECT - DailyTimelineView pattern
.contentShape(Rectangle())
.onTapGesture {
    guard showReflectionInput else { return }
    // Keyboard only - input bar stays visible with text preserved
    isReflectionFocused = false
    Keyboard.dismiss()
}

// WRONG - This loses text!
.dismissKeyboardOnTap { closeKeyboard() }  // closeKeyboard sets showReflectionInput = false
```

---

### Issue 3: Content Shows Through Transparent Input Bar

**Symptom**: When scrolled content overlaps with the input bar, content is visible through the text field.

**Root Cause**: Text field background was semi-transparent (`Color.white.opacity(0.08)`).

**Solution**: Use opaque background for the text field.

```swift
// In BottomInputBar.swift
.background(
    RoundedRectangle(cornerRadius: 20)
        .fill(DesignTokens.CosmosColors.background)  // Opaque, not transparent
)
```

---

## Correct Implementation Pattern

### Parent View State

```swift
@State private var showReflectionInput = false
@FocusState private var isReflectionFocused: Bool
@State private var reflectionText = ""
```

### Tap Gesture (Keyboard Dismiss Only)

```swift
ScrollView { ... }
    .scrollDismissesKeyboard(.interactively)
    .contentShape(Rectangle())
    .onTapGesture {
        guard showReflectionInput else {
            // Handle other focus states if needed
            return
        }
        // Keyboard only - input bar stays
        isReflectionFocused = false
        Keyboard.dismiss()
    }
```

### SafeAreaInset with BottomInputBar

```swift
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
            onSubmit: {
                isReflectionFocused = false
                showReflectionInput = false
                Keyboard.dismiss()
            }
        )
    }
}
```

### ReflectionInputSection (Trigger)

```swift
ReflectionInputSection(
    text: reflectionText,
    isEditing: showReflectionInput,
    onTap: {
        showReflectionInput = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isReflectionFocused = true
        }
    }
)
```

---

## Anti-Patterns (Do NOT Do)

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Missing `onSubmit` | Submit button won't close input bar | Always provide `onSubmit` |
| `closeKeyboard()` sets `showReflectionInput = false` | Background tap loses text | Only dismiss keyboard on tap, not input bar |
| `.dismissKeyboardOnTap { closeKeyboard() }` with input bar | Same as above | Use custom `onTapGesture` |
| Transparent text field background | Content shows through | Use `DesignTokens.CosmosColors.background` |
| Different tap behavior between screens | User confusion | Keep DailyTimelineView and EditRecordView identical |
| `.lineLimit()` on Reflection text | Long text truncated with "..." | Do NOT use lineLimit for Reflection display |

---

## Checklist: Adding BottomInputBar to a New Screen

- [ ] Add `@State private var showInput = false`
- [ ] Add `@FocusState private var isFocused: Bool`
- [ ] Provide `onSubmit` handler that closes input bar
- [ ] Provide `onExpand` handler that closes input bar and opens sheet
- [ ] Use `onTapGesture` that only dismisses keyboard (not input bar) when input is active
- [ ] Test: Type text → tap background → verify text is preserved and input bar stays
- [ ] Test: Type text → press submit → verify text is saved and input bar closes
- [ ] Test: Scroll content → verify no transparency issues
- [ ] Compare behavior with DailyTimelineView as reference

---

## Affected Files

| File | Role |
|------|------|
| `BottomInputBar.swift` | Component implementation |
| `ReflectionInputSection.swift` | Shared trigger card component |
| `DailyTimelineView.swift` | Reference implementation (History) |
| `EditRecordView.swift` | Must match DailyTimelineView behavior |

---

## Historical Issues

| Date | File | Issue | Fix |
|------|------|-------|-----|
| 2025-12-17 | EditRecordView.swift | Submit button didn't close input bar | Added `onSubmit` handler |
| 2025-12-17 | EditRecordView.swift | Background tap closed input bar and lost text | Changed from `dismissKeyboardOnTap` to custom `onTapGesture` |
| 2025-12-17 | BottomInputBar.swift | Content visible through transparent text field | Changed to opaque background |
| 2025-12-17 | ReflectionInputSection.swift | Long text truncated with "..." | Removed `.lineLimit(3)` |

---

## Related Documentation

- `_guide-keyboard.md` - General keyboard interaction guidelines
- `_guide-daily-reflection.md` - Daily reflection feature rules

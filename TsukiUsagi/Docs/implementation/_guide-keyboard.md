# Keyboard Interaction Guidelines

This document defines the app-wide rules for how the on-screen keyboard behaves in all editable contexts.
It ensures consistency, accessibility, and predictable teardown across screens that use `@FocusState`, keyboard toolbars, or inline editors.

## 1. Focus Management

- Every editable control that can summon the keyboard must be paired with a dedicated `@FocusState` binding.
- Components that embed editable controls (e.g., inline editors) are responsible for exposing a binding so parent views can manage focus.
- Views must clear focus in `onDisappear` to avoid hidden/lingering keyboards during navigation transitions.

## 2. Keyboard Toolbar / Floating Button

- Provide a keyboard toolbar via `ToolbarItemGroup(placement: .keyboard)` for every screen that keeps editing inline.
- The dismissal control must use the `keyboard.chevron.compact.down` system symbol. Prefer `Label("Close", systemImage: ...)` so text + icon are consistent with TimerEditView.
- Clearing focus is the responsibility of the hosting view (e.g., `focusedField = nil`). Only after focus is cleared should the action call the shared `Keyboard.dismiss()` helper.
- The helper itself must **never** attempt to manipulate focus state.
- If a floating button is used (e.g., `EditableModal`), reuse `KeyboardCloseButton` so visual styling and accessibility text match the toolbar version.

## 3. Dismiss Gestures

- Offer at least one non-toolbar dismissal path: `.dismissKeyboardOnTap { ... }`, `.scrollDismissesKeyboard(.interactively)`, or both.
- Background gestures should clear focus in the caller before delegating to `Keyboard.dismiss()`.
- Do not rely solely on gestures—keep the explicit Close button for discoverability and accessibility.

## 4. Insets & Layout Safety

- Default: Use the shared `keyboardAwareInset()` (or equivalent) driven by `keyboardWillChangeFrameNotification`.
- When a view already reserves fixed bottom padding (e.g., card gutters), call `keyboardAwareInset(baseBottomPadding:)` so the shared inset subtracts that spacing and prevents double margins.
- Inline editors that need their own scroll offset can apply `keyboardAwareBottomPadding(baseBottomPadding:)` to the card/container so the keyboard delta is scoped locally without re-adding existing padding.
- Apply inset changes on the main thread and consider disabling animations if layout jumps occur.
- Keep these adjustments in the view layer—view models should remain unaware of keyboard height.
- Never store keyboard height in a view model or observable object; treat it as a transient view concern only.

### 4.1 Exception: Bottom Padding Lift (List Editors)

For list-style editors where forced scroll-to-center causes “jumping” (e.g., Manage Descriptions), prefer a layout-based approach:

- Use a named scroll coordinate space (e.g., `"DescScroll"`) and measure both:
  - the focused row bottom Y in that named space, and
  - the viewport height in the same named space.
- Compute a dynamic bottom padding (or `safeAreaInset(edge:.bottom)`) as the exact deficit needed to keep the focused row above the keyboard with a small margin (e.g., 16–24pt), and clamp to a reasonable maximum (e.g., 260–320pt).
- Disable forced scroll in `EditableModal` by setting `ensureVisibleMode: .none` for these screens to avoid aggressive re-centering.
- Avoid double insets: set `keyboardAwareInset(baseBottomPadding: 0)` or remove it entirely on the same view that supplies the dynamic bottom padding.
- Debounce re-computation (~60–100ms) on keyboard frame changes and orientation transitions to improve stability.

## 5. Accessibility

- Add accessibility labels to toolbar buttons (e.g., “Close Keyboard”).
- Verify Tab / switch-control navigation can reach the dismissal control.
- Ensure VoiceOver announces focus changes when dismissing the keyboard.

## 6. Exceptions / Documentation

- Screens that always dismiss the entire modal (e.g., `MemoEditView`) may skip inline close controls, but their rationale must be documented in the relevant spec or README.
- When deviating from the default toolbar+gesture pattern, add a note in the pull request and update this guideline if the exception becomes permanent.

## 7. Consistency Checklist

Before shipping any screen with inline editing:

- [ ] Toolbar (or floating button) uses the keyboard icon + “Close” label and clears focus before calling `Keyboard.dismiss()`.
- [ ] Background tap and/or scroll dismissal is in place without breaking core gestures.
- [ ] `keyboardAwareInset()` (or equivalent) keeps bottom content visible.
- [ ] Focus is cleared before calling `Keyboard.dismiss()` and again in `onDisappear` to guarantee teardown.
- [ ] Behaviour matches TimerEditView unless an exception is documented.

Following these rules keeps keyboard behaviour predictable for users and reduces regressions when we add new inline editors.

## 8. Initial Keyboard Delay (Cold Start)

### 8.1 Problem Description

When the keyboard is displayed for the **first time after app launch**, there is a noticeable delay (typically 0.3–1.0 seconds). This delay only occurs once per app lifecycle—subsequent keyboard appearances are instant.

### 8.2 Root Cause

This is an **iOS system-level behavior**, not an app bug:

- **Independent system process**: The keyboard runs as a separate system process
- **First-time initialization**: Language settings, predictive engine, personal dictionary loading
- **Resource preparation**: Screen size, orientation, accessibility settings application
- **Xcode 14+ SDK**: Since Xcode 14, keyboard appearance takes longer than previous SDKs ([Apple Developer Forums](https://developer.apple.com/forums/thread/721198))

### 8.3 Attempted Solution: HiddenKeyboardWarmer

In July 2025, a pre-warming approach was evaluated:

```swift
// ⚠️ NOT RECOMMENDED - Documented for historical reference only
struct HiddenKeyboardWarmer: View {
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: .constant(""))
            .opacity(0.01)
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .focused($isFocused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = false
                    }
                }
            }
    }
}
```

### 8.4 Why Pre-Warming Doesn't Work

The approach was **rejected** due to fundamental limitations:

| Issue | Description |
|-------|-------------|
| **Keyboard cannot be hidden** | System-level component ignores app opacity/visibility |
| **Layout disruption** | Even invisible TextFields trigger keyboard layout adjustments |
| **Visual flickering** | Keyboard briefly appears then disappears |
| **Excessive execution** | Runs on every screen transition, not just once |
| **Architecture conflict** | Contradicts iOS design philosophy |

### 8.5 Project Decision

**Accept the initial delay** as an iOS system characteristic:

- **Do NOT implement** HiddenKeyboardWarmer or similar workarounds
- **Do NOT** attempt to pre-initialize the keyboard
- **Keep implementation simple** and predictable
- **Wait for Apple** to provide an official solution in future iOS versions

### 8.6 Alternative UX Improvements

Instead of technical workarounds, consider these approaches:

- **Haptic feedback**: Provide immediate tactile response on input field tap
- **Loading indicator**: Show subtle activity indicator during first keyboard appearance
- **Design for expectation**: Accept minor delay as natural app behavior
- **Natural initialization flow**: Design app flow so first keyboard use isn't critical

### 8.7 Related Issues

- **TabView + Keyboard bug**: First keyboard in TabView may trigger `onAppear` for all tab views ([Apple Developer Forums](https://developer.apple.com/forums/thread/659933))
- **SwiftUI TextEditor limitations**: No built-in modifiers for keyboard issues; consider `UIViewRepresentable` with `UITextView` for complex cases
- **Animation sync issues**: SwiftUI animations cannot perfectly sync with keyboard animations

### 8.8 Historical References

- `fujiko_memo/.../78_2025-07-14_keyboard_initialization_delay.md` - Initial investigation
- `fujiko_memo/.../80_2025-07-15_hidden_keyboard_warmer_design_limitation.md` - Final decision

## 9. Revision History

| Date | Author | Summary |
|------|--------|---------|
| 2025-10-09 | Azu | Initial formalization of keyboard behaviour rules |
| 2025-10-10 | Fujiko | Clarified dismiss responsibilities and inset scope |
| 2025-10-10 | Kazumi | Added "Bottom Padding Lift" exception for list editors and coordinate-space guidance |
| 2025-12-16 | Claude | Added "Initial Keyboard Delay (Cold Start)" section documenting iOS system limitation and project decision |

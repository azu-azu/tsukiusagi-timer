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

- Use the shared `keyboardAwareInset()` (or equivalent) driven by `keyboardWillChangeFrameNotification`; avoid ad-hoc bottom padding.
- When a view already reserves fixed bottom padding (e.g., card gutters), call `keyboardAwareInset(baseBottomPadding:)` so the shared inset subtracts that spacing and prevents double margins.
- Inline editors that need their own scroll offset can apply `keyboardAwareBottomPadding(baseBottomPadding:)` to the card/container so the keyboard delta is scoped locally without re-adding existing padding.
- Apply inset changes on the main thread and consider disabling animations if layout jumps occur.
- Keep these adjustments in the view layer—view models should remain unaware of keyboard height.
- Never store keyboard height in a view model or observable object; treat it as a transient view concern only.

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

## 8. Revision History

| Date | Author | Summary |
|------|--------|---------|
| 2025-10-09 | Azu | Initial formalization of keyboard behaviour rules |
| 2025-10-10 | Fujiko | Clarified dismiss responsibilities and inset scope |

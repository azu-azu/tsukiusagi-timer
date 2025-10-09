# Keyboard Interaction Guidelines

This document outlines the rules we follow to provide a consistent and accessible keyboard experience across the app.

## 1. Focus Management

- Every editable control that can summon the keyboard must be paired with a dedicated `@FocusState` binding.
- Components that embed editable controls (e.g., inline editors) are responsible for exposing a binding so parent views can manage focus.
- Views must clear focus in `onDisappear` to avoid hidden/lingering keyboards during navigation transitions.

## 2. Keyboard Toolbar

- Present a keyboard toolbar using `ToolbarItemGroup(placement: .keyboard)` whenever the view relies on inline editing.
- Include a **Close** button that clears focus for all fields that can summon the keyboard in the scope of the current screen.
- Reuse the “Close” copy from TimerEditView to maintain consistent voice; add an accessibility identifier where UI tests require.

## 3. Dismiss Gestures

- Provide at least one non-toolbar dismissal gesture (e.g., background `TapGesture`, scroll dismissal).
- Avoid gestures that interfere with core interactions (e.g., avoid hijacking scroll gestures or buttons).
- When using `scrollDismissesKeyboard(_:)`, preserve the explicit Close button for clarity.

## 4. Insets & Layout Safety

- Ensure content remains visible when the keyboard is up by applying safe-area insets or bottom padding driven by keyboard notifications.
- Animate inset changes with `.easeInOut` or disable animations if the layout jumps (e.g., with `withAnimation(.none)` or by tweaking transactions).
- Do not modify view-model state while adjusting insets; keep layout concerns in the view layer.

## 5. Accessibility

- Add accessibility labels to toolbar buttons (e.g., “Close Keyboard”).
- Verify Tab / switch-control navigation can reach the dismissal control.
- Ensure VoiceOver announces focus changes when dismissing the keyboard.

## 6. Consistency Checklist

Before shipping any screen with inline editing:

- [ ] There is a keyboard toolbar with a Close button.
- [ ] Background tap or scroll dismisses the keyboard.
- [ ] Bottom content is not obscured when the keyboard appears.
- [ ] Focus is cleared on screen exit.
- [ ] Behaviour matches TimerEditView where applicable.

Following these rules keeps keyboard behaviour predictable for users and reduces regressions when we add new inline editors.

## Quiet Moon状態からのSTART時アニメーション不発火問題 - 修正ガイド

This document records the root cause, fix, and why the v1.1.0 fix was insufficient for this specific animation issue.

Update 2025-11-05: Fixed animation subscription not being reestablished after `performCompleteStateReset()` removes all cancellables.

### Goals
- Understand why animation doesn't fire when starting from Quiet Moon state
- Prevent regression by documenting the subscription lifecycle
- Clarify the difference between v1.1.0 fix (reset button) and this fix (animation)

> Meta note: This is a follow-up fix to v1.1.0. The v1.1.0 fix addressed the reset button being disabled; this fix addresses animation subscription being lost.

---

## Problem Statement

**Symptom**: When pressing START button from Quiet Moon state, the timer animation (yellow flash + scale) does not fire.

**Affected Flow**: Quiet Moon → START button
**Normal Flow**: Works correctly (timer animation fires as expected)

---

## Root Cause Analysis

### Primary Cause: Subscription Loss After `cancellables.removeAll()`

**Flow**:
1. `startFromQuietMoon()` calls `performCompleteStateReset()`
2. `performCompleteStateReset()` calls `cancellables.removeAll()` (line 226)
3. This removes **all** Combine subscriptions, including:
   - `animationController.startPulse` → `timerVM.startPulse` subscription
   - Other state manager subscriptions
4. `triggerStartAnimations()` is called (line 269)
5. `animationController.startPulse.send()` is dispatched via `DispatchQueue.main.async`
6. **No subscription exists** → `timerVM.startPulse` never receives the value
7. UI (`StartPulseAnimationModifier`) never receives the pulse → animation doesn't fire

### Secondary Cause: Incorrect API Usage (`subscribe` method)

**Issue**: `setupBindings()` and initial `reestablishBindings()` used `.subscribe()` method which doesn't exist in standard Combine.

**Impact**: Even if called, the subscription wouldn't work correctly.

---

## Why v1.1.0 Fix Didn't Address This

### v1.1.0 Fix (v1.1.0_2025-10-19_architectural-refinement.md)

**Problem Fixed**: "静かな月状態でリセットタイマーが動作しない問題を修正"
- **Scope**: Reset timer button being disabled in Quiet Moon state
- **Fix**: Added `canResetNow` property to enable reset button
- **Impact**: UI control (button enabled/disabled state)

**What v1.1.0 Didn't Address**:
- Subscription lifecycle after `cancellables.removeAll()`
- Animation subscription reestablishment
- `performCompleteStateReset()` was likely introduced in v1.1.0, but subscription restoration wasn't implemented

**Why v1.1.0 Fix Wasn't Enough**:
- v1.1.0 focused on **UI control** (button state)
- This issue is about **Combine subscription lifecycle**
- `performCompleteStateReset()` was added to fix state reset, but subscription restoration was overlooked
- The animation subscription was silently lost without any indication

---

## Solution Implementation

### Fix 1: Add `reestablishBindings()` Method

**File**: `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel.swift`

**Implementation**:
```swift
/// アニメーション購読を再確立（performCompleteStateReset後用）
///
/// `performCompleteStateReset()`で`cancellables.removeAll()`により
/// 購読が解除された後、アニメーション購読を復元するために使用
func reestablishBindings() {
    guard let controller = animationController as? TimerAnimationController else { return }
    // startPulse を ViewModel 側に橋渡し
    // setupBindings()と同じ実装を使用
    controller.startPulse
        .sink { [weak self] _ in
            self?.startPulse.send()
        }
        .store(in: &cancellables)
}
```

### Fix 2: Call `reestablishBindings()` After `cancellables.removeAll()`

**File**: `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel+SessionControl.swift`

**Implementation**:
```swift
func performCompleteStateReset() {
    // 0) UI分岐を速攻で開放
    isSessionFinished = false

    // 1) 旧購読の全破棄
    cancellables.removeAll()

    // ... existing state reset code ...

    // 6) セッションマネージャーのリセット
    sessionManager.resetSession()

    // 7) アニメーション購読の再確立（cancellables.removeAll()で解除された購読を復元）
    reestablishBindings()
}
```

### Fix 3: Correct API Usage (`sink` instead of `subscribe`)

**File**: `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel.swift`

**Changed**:
- `setupBindings()`: Changed from `.subscribe(startPulse)` to `.sink { [weak self] _ in self?.startPulse.send() }`
- `reestablishBindings()`: Uses `.sink` (standard Combine API)

---

## Why Normal Start Flow Works

**Normal Flow** (`startTimerNormalFlow()`):
- Does **NOT** call `cancellables.removeAll()`
- Subscription established in `setupBindings()` remains intact
- `triggerStartAnimations()` → `animationController.startPulse.send()` → `timerVM.startPulse` receives value → UI animation fires ✅

**Quiet Moon Flow** (before fix):
- Calls `performCompleteStateReset()` → `cancellables.removeAll()` → subscription lost
- `triggerStartAnimations()` → `animationController.startPulse.send()` → **no subscription** → UI animation doesn't fire ❌

---

## Code Locations – Core Logic

### Subscription Setup
- **Initial**: `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel.swift`
  - `setupBindings()` (line 177-202): Establishes initial subscriptions
  - `reestablishBindings()` (line 205-212): Reestablishes animation subscription after reset

### Subscription Removal
- **Reset**: `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel+SessionControl.swift`
  - `performCompleteStateReset()` (line 221-247): Removes all subscriptions, then calls `reestablishBindings()`

### Animation Trigger
- **Controller**: `TsukiUsagi/Features/Timer/Controllers/TimerAnimationController.swift`
  - `triggerStartAnimations()` (line 37-44): Sends `startPulse` via `DispatchQueue.main.async`

### UI Subscription
- **View**: `TsukiUsagi/Features/Timer/Views/TimerPanel.swift`
  - `.startPulseAnimation(publisher: timerVM.startPulse.eraseToAnyPublisher())` (line 35)
- **Modifier**: `TsukiUsagi/CrossFeatureUI/Controls/StartPulseAnimationModifier.swift`
  - `onReceive(publisher)` (line 16): Receives pulse and triggers animation

---

## Invariants / Checkpoints

- **Subscription Lifecycle**:
  - If `cancellables.removeAll()` is called, **always** reestablish critical subscriptions
  - Animation subscription (`startPulse`) is critical and must be restored
- **API Usage**:
  - Use `.sink { }` for `PassthroughSubject` → `PassthroughSubject` forwarding
  - Never use `.subscribe()` (not a standard Combine API)
- **Timing**:
  - `reestablishBindings()` must be called **before** `triggerStartAnimations()`
  - Current implementation: `reestablishBindings()` is called at the end of `performCompleteStateReset()`, which is called before `triggerStartAnimations()` in `startFromQuietMoon()` ✅

---

## Testing Checklist

| Case | Action | Expected Result |
|------|--------|-----------------|
| Quiet Moon → START | Press START from Quiet Moon state | Timer animation (yellow flash + scale) fires once |
| Normal Start | Start timer from idle state | Timer animation fires normally |
| Reset → Start | Press Reset, then START | Timer animation fires normally |
| Multiple Starts | Press START multiple times rapidly | Animation fires once per press (no duplicate subscriptions) |

---

## Rationale (Why This Design)

1. **Subscription Lifecycle Management**:
   - `cancellables.removeAll()` is necessary to clean up old subscriptions
   - But critical subscriptions must be restored immediately after
   - `reestablishBindings()` provides explicit restoration point

2. **Separation of Concerns**:
   - `performCompleteStateReset()` handles state cleanup
   - `reestablishBindings()` handles subscription restoration
   - Clear responsibility boundaries

3. **Minimal Impact**:
   - Only restores animation subscription (not all subscriptions)
   - Other subscriptions are recreated as needed in normal flow
   - Prevents unnecessary overhead

---

## Notes for Future Changes

- **If adding new subscriptions in `setupBindings()`**:
  - Consider if they need to be restored in `reestablishBindings()`
  - Document which subscriptions are critical vs. transient
- **If changing `performCompleteStateReset()` logic**:
  - Ensure `reestablishBindings()` is still called at the end
  - Verify subscription restoration order
- **If modifying animation controller**:
  - Ensure `startPulse` subscription remains compatible
  - Test Quiet Moon → START flow after changes

---

## Related Documentation

- **v1.1.0 Release Notes**: `docs/releases/v1.1.0_2025-10-19_architectural-refinement.md`
  - Fixed: Reset timer button being disabled in Quiet Moon state
  - **Not Fixed**: Animation subscription lifecycle (this document)
- **Notification Guide**: `docs/_guide-notifications-fg-bg.md`
  - Similar pattern: Documenting behavior to prevent regression

---

## Vocabulary（英 | 日）

| English | 日本語 |
|---------|--------|
| Subscription | 購読 |
| Cancellable | キャンセル可能オブジェクト |
| PassthroughSubject | パススルーサブジェクト |
| Combine | コンバインフレームワーク |


## Focus/Rest Notifications - Foreground/Background Policy

This document records the final behavior, design rules, and code locations for the timer phase notifications (Focus/Rest) so the same problems do not recur.

### Goals
- Deliver stable, understandable notifications without surprise removals.
- Keep foreground UX smooth; accept OS constraints in background.
- Make behaviors explicit and easy to maintain.

> Meta note: The following is an intentional UX policy (not a temporary workaround).

### Notification Policy Matrix (Final)
- Foreground (FG)
  - Rest: shows and stays (no instant vanish).
  - Focus: shows normally.
  - We clean only the previous-phase delivered right before presentation (willPresent). Same‑phase duplicates are avoided at schedule-time.

- Background (BG)
  - Rest: shows and stays on the Lock Screen.
  - Focus: WILL NOT surface while Rest is still present. User must clear Rest first (explicitly accepted policy).
  - No previous-phase cleanup is performed in BG.

### Implementation & Code Mapping

```
[Schedule] ── (same‑phase cleanup) ──► add request
      │
      ▼
[Delivered Rest visible]
      │
      ├─ App BG: no more cleanup (Rest stays)
      │
      └─ App FG: willPresent ── (previous‑phase cleanup) ──► present
```

Do / Don’t rules
- Identifiers
  - Do: Use unique request identifiers: `"<prefix>.<epoch>.<UUID8>"` for each scheduled notification.
  - Do: Set `content.threadIdentifier` as follows:
    - FG: `prefix` (grouping by phase; better list appearance)
    - BG: `uniqueId` (reduce OS coalescing)

- Delivered cleanup
  - Do (schedule-time): Clear only SAME-PHASE older delivered before adding a new request.
  - Do (FG): In `willPresent`, clear only the PREVIOUS‑PHASE delivered right before presentation.
  - Don’t (BG): Perform previous-phase cleanup. We intentionally keep Rest until the user clears it.

- Priorities (iOS 15+)
  - BG: Rest → `.active` (normal), Focus → `.timeSensitive`.
  - FG: keep `.timeSensitive` where appropriate (current setup preserved).

- Timing
  - BG: Focus is staggered by +5s (constant) to avoid same-second coalescing. This is a smoothing aid, not a guarantee.
  - Fallback/cooldown/one‑at‑a‑time policies: disabled by design (kept out to match the accepted product behavior).

### Code Locations – Core Logic (Where to look / change)
- Foreground cleanup (previous‑phase only):
  - `TsukiUsagi/Entry/AppDelegate.swift`
    - `userNotificationCenter(_:willPresent:withCompletionHandler:)`
    - Calls: `NotificationManager.shared.clearPreviousPhaseDeliveredOnly(forIncoming:)`

- Schedule-time behavior (shared FG/BG):
  - `TsukiUsagi/Features/Timer/Services/NotificationManager.swift`
    - `scheduleSessionEndNotification(at:phase:timeSensitive:cleanupPendingPrefixes:)`
    - `scheduleNotificationAtAbsoluteTime(endAt:phase:timeSensitive:)`
      - SAME‑PHASE cleanup: `clearDeliveredSamePhaseOnly(forIncomingId:phase:)`
      - FG/BG threadIdentifier selection (FG: prefix, BG: uniqueId)
      - BG Focus stagger (+5s)
    - Pending helpers: `removePending(for:)` / `removePending(for: [PomodoroPhase])`
    - Previous‑phase cleanup (FG‑only call site): `clearPreviousPhaseDeliveredOnly(forIncoming:)`

### Code Locations – High‑level API
- `TsukiUsagi/Features/Timer/Services/PhaseNotificationService.swift`
  - Chained schedule: `scheduleChainedSessionEnds(workEndAt:breakEndAt:timeSensitive:)`
  - Idempotent Focus schedule: `ensureFocusAt(breakEndAt:timeSensitive:)`
- `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel+SessionControl.swift`
  - `startTimer()` / `resumeTimer()` use the APIs above to schedule.

### Invariants / Checkpoints
- Always keep request identifiers unique (prefix + epoch + UUID8).
- FG
  - threadIdentifier = phase `prefix`.
  - willPresent cleans previous‑phase only; never clean same‑phase here.
- BG
  - threadIdentifier = `uniqueId`.
  - Do not remove previous‑phase delivered at schedule-time.
  - Focus is staggered by +5s; no fallback/one‑at‑a‑time policies.
- Schedule-time
  - Clean only same‑phase older delivered.

### Testing Checklist (with expected outcomes)

| Case               | Action                                 | Expected Result                                      |
| ------------------ | -------------------------------------- | ---------------------------------------------------- |
| FG Work → Rest     | End work session in FG                 | Rest alert shows and remains visible (no instant vanish) |
| FG Rest → Focus    | At next phase switch                   | Focus alert shows normally                           |
| BG Work → Rest     | End work session while app in BG       | Rest banner stays on Lock Screen                     |
| BG Rest → Focus    | Do not clear Rest, wait for Focus time | Focus does not surface until Rest is cleared (policy) |
| Pause/Resume       | Pause and resume timer                 | No duplicate pendings; schedule resynchronizes        |
| Short intervals    | Use short break/work lengths           | FG ok; BG matches policy without surprise removals    |

### Rationale (Why this design)
### Constants (reference)
- `bgFocusStaggerSeconds = 5.0`
  - Purpose: avoid iOS coalescing Focus & Rest notifications in BG when triggers are at the same second.

- iOS aggressively coalesces/suppresses notifications from the same app in BG when a prior banner is present.
- Foreground offers a delegate hook (willPresent) to clean just in time; background doesn’t. To avoid surprise removals in BG, we accept the one‑visible‑at‑a‑time reality and require user clearing.
- Rules concentrate cleanup responsibilities (same‑phase at schedule-time; previous‑phase at FG willPresent) to avoid accidental vanishes.

### Notes for Future Changes
- If you decide to surface Focus in BG regardless of Rest, re‑enable BG previous‑phase cleanup right before scheduling Focus (one‑at‑a‑time). This is intentionally OFF now.
- If UX requires tighter grouping or different priority balances, adjust `threadIdentifier` and `interruptionLevel` with the matrix above in mind.


## Appendix A – Constants & System Notes

### A. Constants (reference)
- `bgFocusStaggerSeconds = 5.0`
  - Purpose: avoid iOS coalescing Focus & Rest notifications in BG when triggers are at the same second.

### B. System Notes
- iOS may coalesce or suppress multiple notifications from the same app in BG when a prior banner is visible.
- Presentation-time hooks exist only in FG (`willPresent`); BG has no equivalent callback.
- Thread policy summary:
  - FG: `threadIdentifier = <phase prefix>` for readable grouping.
  - BG: `threadIdentifier = <uniqueId>` to reduce OS coalescing.



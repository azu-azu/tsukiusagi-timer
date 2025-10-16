# Daily Reflection Implementation Guide

## Purpose
Define non-negotiable rules so the Daily Reflection feature remains stable, simple, and future-proof.

- Single source of truth (SSoT): one Reflection per calendar day
- Robust persistence and migration
- Clear UI and API contracts (no split paths)

## Canonical Model
- Type: `DayReflection { date: Date, text: String, lastUpdatedAt: Date, isPendingSave: Bool }`
- Keying: The reflection is keyed by the day (start-of-day in the current timezone).
  - Always derive the dictionary key via `HistoryDateKey.dayKey(for: date)`.
  - Day keys MUST be stable across DST transitions within the same local day.
  - Save-time fix: compute the dayKey at save-time and persist it; never recompute stored keys at read-time (survives TZ/DST changes).

## Persistence Rules
- File: `TsukiUsagi/Features/History/Services/HistoryStore.swift`
- Storage layout uses a separate reflections array in the persisted payload; on load it is converted into a `[Date: DayReflection]` map using the normalized day key. If multiple entries exist, the one with the latest `lastUpdatedAt` wins.
- Migrations:
  - Legacy “Reflection” session rows are split out and combined (joined by a blank line) into per-day `DayReflection` once.
  - Migrations MUST be idempotent. Never re-insert legacy reflection rows into sessions after migration.

## UI Rules
- File: `TsukiUsagi/Features/History/Views/DailyTimelineView.swift`
- The Daily Timeline always shows a single inline editor for the day’s Reflection. There is no alternate “memo-per-record” UI.
- Never create or display dummy “Reflection/New Reflection” `SessionRecord` rows in the history UI.

### Expand Affordance (Sheet Editor Trigger)
- Location: Right-aligned icon in the section header
  - History: Reflection section header (DailyTimelineView)
  - Edit Record: Reflection/memo section header (TimerEditView)
- Visual: icon-only (no text)
  - System symbol: `arrow.up.left.and.arrow.down.right`
  - Style: `DesignTokens.Fonts.caption`, `DesignTokens.MoonColors.accentBlue`, `.buttonStyle(.plain)`
- Copy/A11y:
  - VoiceOver label must be `Copy.Button.expand`
  - Stable identifiers: `open_reflection_sheet_button`, `open_memo_sheet_button`
- Behavior:
  - On tap: dismiss inline focus/keyboard, then present `LargeTextEditorSheet`
  - Avoid wrapping the button in tap gestures that consume the event (e.g., global keyboard-dismiss taps)
- Do not:
  - Render a text label next to the icon
  - Place the button near primary Save actions; keep it in the header to avoid mis-taps
- Placeholder/copy must use the 3-layer classification (TXT-01) and design tokens (UI-01). No direct `NSLocalizedString` or system fonts.

## API Contracts (UseCases/ViewModels)
- File: `TsukiUsagi/Features/History/ViewModels/HistoryViewModel.swift`
- The ONLY supported way to modify a daily reflection is:
  - `updateReflection(for date: Date, text: String)`
  - `reflectionText(for date: Date)`
  - `reflection(for date: Date)`
- Provide an append convenience to avoid drift in callers:
  - `appendToReflection(for date: Date, newLine: String)` (apply Append Policy, dedupe, then `updateReflection`)
- When adding a new line from other flows (e.g., after session completion), use the append convenience. If not available, APPEND to the existing `DayReflection.text` with a blank line separator, then call `updateReflection` with the combined text.
- Do NOT write Reflection content to `SessionRecord.memo`. That field is legacy and not rendered in the Daily Reflection UI.

### Authoritative Time Source
- Day selection for reflection must use the flow’s authoritative time source.
  - End-of-session/edit flows: use the session `endAt` as the basis for `dayKey`.
  - Never use `Date()` as a fallback for day selection.

### Append Policy
- If `newLine.trimmed` is empty: do nothing.
- If `existing.trimmed` is empty: `combined = newLine`.
- Else: `combined = existing + "\n\n" + newLine`.
- Normalize before save: convert CRLF→LF, strip trailing spaces per line, collapse 3+ consecutive blank lines to 2.
- Use `updateReflection(for: targetDate, text: combined)` to persist and trigger autosave/retry.

### Concurrency & Conflict Resolution
- Mark saves against the exact `lastUpdatedAt` snapshot; if a save response corresponds to an older snapshot than current state, drop it (newer edit wins).
- Access to reflection APIs occurs on a consistent actor/thread (e.g., `@MainActor` gateway or an internal actor) to avoid races.

### Dedupe Policy
- Prevent duplicate appends for identical payloads within a pending window (e.g., hash of `trimmedNewLine + dayKey` while pending).

## Feature Flags
- There is no flag for the daily reflection path. It is always enabled. Do not re-introduce a flag gate (avoids dual paths and drift).

## Error Handling and Save Semantics
- Saves are optimistic with exponential backoff retries. UI should reflect `isPendingSave` and expose a retry action.
- On successful save, mark the exact `lastUpdatedAt` snapshot as saved to avoid stomping newer edits.

## Anti-Patterns (Do Not Do)
- Do not create `SessionRecord` rows named “Reflection” or “New Reflection”.
- Do not persist Reflection content into `SessionRecord.memo` as a way to show it in history.
- Do not branch the UI with feature flags or show multiple Reflection editors per day.
- Do not compute day keys manually; always use `HistoryDateKey.dayKey(for:)`.

## Testing Requirements
- Keep these unit tests (or equivalents) green and update when behavior changes:
  - Migration: legacy reflection rows combine into a single `DayReflection` once, idempotent on subsequent loads.
  - Day key stability across DST within the same local day.
  - Autosave + retry flow toggles `isPendingSave` and clears errors after success.
  - Append behavior from session completion: existing text + blank line + new text (no overwrite).
  - Dedupe: identical line appended within pending window is not duplicated.

## Integration Guidance (Timer → Reflection)
- File: `TsukiUsagi/Features/Timer/Components/TimerEditHeaderView.swift`
- On save from the Edit Record screen:
  - Use Append Policy via the append convenience; then call `updateReflection(for: editedEnd, text: combined)`.
  - Clear per-record memo via `updateLast(..., memo: "")` to avoid divergence (non-negotiable).

## Future Changes Checklist
- Adding a new source of Reflection text? Route it through the Append Policy and `updateReflection`.
- Changing keying or timezone handling? Update `HistoryDateKey` and the day-key tests.
- Modifying persistence? Keep `dictionary(from:)` precedence by `lastUpdatedAt` and preserve idempotent migrations.
- UI edits? Keep a single inline editor per day and respect TXT-01/UI-01/UI-02 rules.

## Operational Notes
- Optional one-time cleanup: if the legacy `historyInlineReflection` key exists in `UserDefaults`, remove it during app bootstrap (harmless if absent).
- Health check on load: detect duplicate keys for the same local day (different UTC midnights), normalize by latest `lastUpdatedAt`, log once.
- Analytics: unify events to daily Reflection semantics (e.g., `reflection_saved(day)`, `reflection_append(day)`), and emit violations like `memo_write_attempt_blocked`.

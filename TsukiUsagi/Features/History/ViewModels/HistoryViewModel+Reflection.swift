import Foundation

// MARK: - Reflection Operations

extension HistoryViewModel {
    func reflectionText(for date: Date) -> String {
        reflectionsByDay[HistoryDateKey.dayKey(for: date)]?.text ?? ""
    }

    func reflection(for date: Date) -> DayReflection? {
        reflectionsByDay[HistoryDateKey.dayKey(for: date)]
    }

    func updateReflection(for date: Date, text: String) {
        let key = HistoryDateKey.dayKey(for: date)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            if reflectionsByDay.removeValue(forKey: key) != nil {
                isSavingReflections = true
                save()
            }
            return
        }

        var reflection = reflectionsByDay[key] ?? DayReflection(
            date: key,
            text: "",
            lastUpdatedAt: Date(),
            isPendingSave: false
        )

        if reflection.text == trimmed {
            return
        }

        reflection.text = trimmed
        reflection.lastUpdatedAt = Date()
        reflection.isPendingSave = true
        reflectionsByDay[key] = reflection
        isSavingReflections = true
        save()
    }

    func retrySaveReflection() {
        reflectionSaveError = nil
        retryPendingSave()
    }

    /// Append a new reflection line to the day's reflection using normalization and short-window dedupe.
    func appendToReflection(for date: Date, newLine raw: String) {
        let newLine = normalizeReflectionText(raw)
        guard !newLine.isEmpty else { return }
        let existing = reflectionText(for: date).trimmingCharacters(in: .whitespacesAndNewlines)
        guard dedupeAllowReflection(day: HistoryDateKey.dayKey(for: date), text: newLine) else { return }
        let combined = existing.isEmpty ? newLine : existing + "\n\n" + newLine
        updateReflection(for: date, text: normalizeReflectionText(combined))
    }
}

// MARK: - Reflection Helpers

extension HistoryViewModel {
    /// Normalize reflection text: CRLF->LF, trim trailing spaces per line, collapse 3+ blank lines to 2
    func normalizeReflectionText(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let parts = result.split(separator: "\n", omittingEmptySubsequences: false)
        result = parts.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Short-window dedupe for identical immediate appends per day
    func dedupeAllowReflection(day: Date, text: String) -> Bool {
        if Self.recentReflectionAppends[day] == text { return false }
        Self.recentReflectionAppends[day] = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            Self.recentReflectionAppends[day] = nil
        }
        return true
    }

    func markReflectionsAsSaved(_ snapshotReflections: [Date: DayReflection]) {
        var updated = reflectionsByDay
        for (date, reflection) in snapshotReflections where reflection.isPendingSave {
            guard let current = updated[date],
                current.lastUpdatedAt == reflection.lastUpdatedAt else {
                continue
            }
            var saved = current
            saved.isPendingSave = false
            updated[date] = saved
        }
        reflectionsByDay = updated
    }
}

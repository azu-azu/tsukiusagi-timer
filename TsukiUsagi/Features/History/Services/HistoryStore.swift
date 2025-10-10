import Foundation

struct HistorySnapshot {
    var migrationVersion: Int
    var sessions: [SessionRecord]
    var reflections: [Date: DayReflection]
}

struct HistoryStore {
    private let file = "history.json"

    private let baseURL: URL

    init(baseURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.baseURL = baseURL
    }

    private var url: URL {
        baseURL.appendingPathComponent(file)
    }

    // MARK: - JSON coder/decoder with ISO-8601 dates

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // MARK: - Save

    /// 非同期に保存し、結果をコールバックで返す
    func save(_ snapshot: HistorySnapshot, completion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            let payload = PersistedHistory(
                migrationVersion: snapshot.migrationVersion,
                sessions: snapshot.sessions,
                reflections: Array(snapshot.reflections.values)
            )
            let encoded = try encoder.encode(payload)
            let fileURL = url // capture for async write

            DispatchQueue.global(qos: .utility).async {
                do {
                    try encoded.write(
                        to: fileURL,
                        options: [.atomic, .completeFileProtectionUnlessOpen]
                    )
                    completion?(.success(()))
                } catch {
                    #if DEBUG
                        print("[history_save_failed] HistoryStore save failed:", error)
                    #endif
                    completion?(.failure(error))
                }
            }
        } catch {
            #if DEBUG
                print("[history_save_failed] HistoryStore encoding failed:", error)
            #endif
            completion?(.failure(error))
        }
    }

    // MARK: - Load

    func load() -> HistorySnapshot {
        guard let raw = try? Data(contentsOf: url) else {
            return HistorySnapshot(migrationVersion: 1, sessions: [], reflections: [:])
        }

        if let payload = try? decoder.decode(PersistedHistory.self, from: raw) {
            if payload.migrationVersion >= 1 {
                return HistorySnapshot(
                    migrationVersion: payload.migrationVersion,
                    sessions: payload.sessions,
                    reflections: Self.dictionary(from: payload.reflections)
                )
            } else {
                return migrateLegacyPayload(payload)
            }
        }

        if let legacySessions = try? decoder.decode([SessionRecord].self, from: raw) {
            return migrateLegacySessions(legacySessions)
        }

        return HistorySnapshot(migrationVersion: 1, sessions: [], reflections: [:])
    }
}

// MARK: - Migration helpers

private extension HistoryStore {
    struct PersistedHistory: Codable {
        var migrationVersion: Int
        var sessions: [SessionRecord]
        var reflections: [DayReflection]
    }

    static func dictionary(from reflections: [DayReflection]) -> [Date: DayReflection] {
        reflections.reduce(into: [:]) { result, reflection in
            let key = HistoryDateKey.dayKey(for: reflection.date)
            if let existing = result[key], existing.lastUpdatedAt > reflection.lastUpdatedAt {
                return
            }
            var normalized = reflection
            normalized.date = key
            result[key] = normalized
        }
    }

    func migrateLegacyPayload(_ payload: PersistedHistory) -> HistorySnapshot {
        backupHistoryFile()
        let migrated = splitReflectionRecords(from: payload.sessions)
        let snapshot = HistorySnapshot(
            migrationVersion: 1,
            sessions: migrated.sessions,
            reflections: migrated.reflections
        )
        persistMigratedSnapshot(snapshot)
        return snapshot
    }

    func migrateLegacySessions(_ sessions: [SessionRecord]) -> HistorySnapshot {
        backupHistoryFile()
        let migrated = splitReflectionRecords(from: sessions)
        let snapshot = HistorySnapshot(
            migrationVersion: 1,
            sessions: migrated.sessions,
            reflections: migrated.reflections
        )
        persistMigratedSnapshot(snapshot)
        return snapshot
    }

    func splitReflectionRecords(from sessions: [SessionRecord]) -> (sessions: [SessionRecord], reflections: [Date: DayReflection]) {
        var filteredSessions: [SessionRecord] = []
        var textsByDay: [Date: [String]] = [:]
        var updatedAtByDay: [Date: Date] = [:]

        for record in sessions {
            if isReflectionRecord(record) {
                let key = HistoryDateKey.dayKey(for: record.start)
                if let memo = record.memo?.trimmingCharacters(in: .whitespacesAndNewlines), !memo.isEmpty {
                    textsByDay[key, default: []].append(memo)
                }
                let candidate = max(record.start, record.end)
                if let current = updatedAtByDay[key] {
                    if candidate > current {
                        updatedAtByDay[key] = candidate
                    }
                } else {
                    updatedAtByDay[key] = candidate
                }
                continue
            }
            filteredSessions.append(record)
        }

        var reflections: [Date: DayReflection] = [:]
        for (day, texts) in textsByDay {
            let combined = texts.joined(separator: "\n\n")
            let updatedAt = updatedAtByDay[day] ?? day
            reflections[day] = DayReflection(
                date: day,
                text: combined,
                lastUpdatedAt: updatedAt,
                isPendingSave: false
            )
        }

        return (filteredSessions, reflections)
    }

    func isReflectionRecord(_ record: SessionRecord) -> Bool {
        let normalized = record.sessionName.lowercased()
        return normalized == "reflection" || normalized == "new reflection"
    }

    func backupHistoryFile() {
        let timestamp = backupFormatter.string(from: Date())
        let backupURL = url.deletingLastPathComponent()
            .appendingPathComponent("history-\(timestamp).backup.json")
        guard !FileManager.default.fileExists(atPath: backupURL.path) else { return }
        do {
            try FileManager.default.copyItem(at: url, to: backupURL)
        } catch {
            #if DEBUG
                print("[history_backup_failed] Could not create backup:", error)
            #endif
        }
    }

    func persistMigratedSnapshot(_ snapshot: HistorySnapshot) {
        let payload = PersistedHistory(
            migrationVersion: snapshot.migrationVersion,
            sessions: snapshot.sessions,
            reflections: Array(snapshot.reflections.values)
        )
        guard let encoded = try? encoder.encode(payload) else { return }
        do {
            try encoded.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            #if DEBUG
                print("[history_migration_persist_failed]", error)
            #endif
        }
    }
}


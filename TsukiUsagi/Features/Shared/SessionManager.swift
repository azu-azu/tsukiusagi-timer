import Combine
import Foundation

@MainActor
class SessionManager: ObservableObject {
    @Published private(set) var sessions: [SessionItem] = []

    // Convenience getters
    var fixedSessions: [SessionItem] { sessions.filter { $0.isFixed } }
    var customSessions: [SessionItem] { sessions.filter { !$0.isFixed } }

    private let userDefaultsKeyV1 = "customSessions"
    private let userDefaultsKeyV2 = "customSessionsV2"
    private let schemaVersionKey = "sessionSchemaVersion"
    private let schemaVersionV2 = 2

    enum SessionError: Error, LocalizedError {
        case duplicate
        case limitExceeded
        case notFound

        var errorDescription: String? {
            switch self {
            case .duplicate:
                return "This session name is already registered."
            case .limitExceeded:
                return "You have reached the maximum number of custom sessions."
            case .notFound:
                return "Session not found."
            }
        }
    }

    init() {
        Task {
            await migrateIfNeededAsync()
            await loadAsync()
            if sessions.isEmpty {
                sessions = SessionItem.fixedSessions
            }
        }
    }

    // MARK: - マイグレーション v1→v2 (async)

    private func migrateIfNeededAsync() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let defaults = UserDefaults.standard
                let currentVersion = defaults.integer(forKey: self.schemaVersionKey)
                guard currentVersion < self.schemaVersionV2 else {
                    continuation.resume()
                    return
                }
                if let data = defaults.data(forKey: self.userDefaultsKeyV1),
                    let oldItems = try? JSONDecoder().decode([OldSessionItem].self, from: data) {
                    // swiftlint:disable:next identifier_name // Issue #4: 一時変数用途の命名ルール明確化（2024年8月目標）
                    // seen: 重複チェック用の一時変数（用途明示）
                    var seen = Set<String>()
                    let migrated: [SessionItem] = oldItems.compactMap { old in
                        let key = old.name.lowercased()
                        guard !seen.contains(key) else { return nil }
                        seen.insert(key)
                        return SessionItem(id: old.id, name: old.name, subtitle: old.detail, isFixed: false)
                    }
                    if let newData = try? JSONEncoder().encode(migrated) {
                        defaults.set(newData, forKey: self.userDefaultsKeyV2)
                        defaults.set(self.schemaVersionV2, forKey: self.schemaVersionKey)
                        print("✅ マイグレーション v1→v2 完了 (", migrated.count, "件)")
                    }
                } else {
                    defaults.set(self.schemaVersionV2, forKey: self.schemaVersionKey)
                }
                continuation.resume()
            }
        }
    }

    // MARK: - データロード (async)

    private func loadAsync() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let defaults = UserDefaults.standard
                if let data = defaults.data(forKey: self.userDefaultsKeyV2),
                    let decoded = try? JSONDecoder().decode([SessionItem].self, from: data) {
                    // swiftlint:disable:next identifier_name
                    // decoded: デコード結果の一時変数（用途明示）
                    Task {
                        await MainActor.run {
                            self.sessions = SessionItem.fixedSessions + decoded
                        }
                        continuation.resume()
                    }
                } else {
                    Task {
                        await MainActor.run {
                            self.sessions = SessionItem.fixedSessions
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }

    // MARK: - データ保存 (async)

    private func saveAsync() async {
        let custom = await MainActor.run { self.sessions.filter { !$0.isFixed } }
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                if let data = try? JSONEncoder().encode(custom) {
                    UserDefaults.standard.set(data, forKey: self.userDefaultsKeyV2)
                }
                continuation.resume()
            }
        }
    }

    // MARK: - CRUD

    func addSession(_ item: SessionItem) throws {
        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sessions.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            throw SessionError.duplicate
        }
        if !item.isFixed && customSessions.count >= 50 {
            throw SessionError.limitExceeded
        }
        var newItem = item
        newItem.name = trimmedName
        newItem.subtitle = item.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        sessions.append(newItem)
        Task { await saveAsync() }
    }

    func editSession(id: UUID, newName: String, newSubtitle: String?) throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else {
            throw SessionError.notFound
        }
        if sessions.contains(where: { $0.name.lowercased() == trimmedName.lowercased() && $0.id != id }) {
            throw SessionError.duplicate
        }
        sessions[idx].name = trimmedName
        sessions[idx].subtitle = newSubtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await saveAsync() }
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        Task { await saveAsync() }
    }
}

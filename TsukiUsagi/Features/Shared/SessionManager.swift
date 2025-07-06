import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published private(set) var customSessions: [SessionItem] = []
    let fixedSessions: [SessionItem] = SessionItem.fixedSessions
    let customSessionLimit = 50
    private let userDefaultsKey = "customSessions"

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
        migrateIfNeeded()
        load()
    }

    var allSessions: [SessionItem] {
        fixedSessions + customSessions
    }

    // MARK: - Migration

    private func migrateIfNeeded() {
        let defaults = UserDefaults.standard
        let key = "didMigrateDetailToSubtitle"

        if !defaults.bool(forKey: key) {
            migrateDetailLabelToSubtitleLabel()
            migrateCustomSessionsIfNeeded()
            defaults.set(true, forKey: key)
            print("✅ マイグレーション全処理完了")
        }
    }

    private func migrateDetailLabelToSubtitleLabel() {
        let defaults = UserDefaults.standard
        if let oldValue = defaults.string(forKey: "detailLabel") {
            defaults.set(oldValue, forKey: "subtitleLabel")
            defaults.removeObject(forKey: "detailLabel")
            print("✅ detailLabel → subtitleLabel 移行完了")
        }
    }

    private func migrateCustomSessionsIfNeeded() {
        let defaults = UserDefaults.standard

        guard let data = defaults.data(forKey: "customSessions") else {
            return
        }

        // 古い model で decode
        if let oldItems = try? JSONDecoder().decode([OldSessionItem].self, from: data) {
            // subtitle に詰め替える
            let newItems: [SessionItem] = oldItems.map {
                SessionItem(id: $0.id, name: $0.name, subtitle: $0.detail)
            }

            if let newData = try? JSONEncoder().encode(newItems) {
                defaults.set(newData, forKey: "customSessions")
                print("✅ customSessions の detail → subtitle 移行完了")
            }
        }
    }

    // MARK: - CRUD

    func addSession(_ item: SessionItem) throws {
        let trimmedName = item.name.trimmed
        guard !allSessions.contains(where: { $0.name == trimmedName }) else {
            throw SessionError.duplicate
        }
        guard customSessions.count < customSessionLimit else {
            throw SessionError.limitExceeded
        }
        var newItem = item
        newItem.name = trimmedName
        newItem.subtitle = item.subtitle?.trimmed
        customSessions.append(newItem)
        save()
    }

    func editSession(id: UUID, newName: String, newSubtitle: String?) throws {
        let trimmedName = newName.trimmed
        guard let idx = customSessions.firstIndex(where: { $0.id == id }) else {
            throw SessionError.notFound
        }
        // 重複チェック（自分以外）
        if allSessions.contains(where: { $0.name == trimmedName && $0.id != id }) {
            throw SessionError.duplicate
        }
        customSessions[idx].name = trimmedName
        customSessions[idx].subtitle = newSubtitle?.trimmed
        save()
    }

    func deleteSession(id: UUID) {
        customSessions.removeAll { $0.id == id }
        save()
    }

    func restoreFromHistory(_ item: SessionItem) throws {
        let trimmedName = item.name.trimmed
        guard !allSessions.contains(where: { $0.name == trimmedName }) else {
            throw SessionError.duplicate
        }
        guard customSessions.count < customSessionLimit else {
            throw SessionError.limitExceeded
        }
        let newItem = SessionItem(
            id: UUID(),
            name: trimmedName,
            subtitle: item.subtitle?.trimmed
        )
        customSessions.append(newItem)
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(customSessions) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([SessionItem].self, from: data) else {
            customSessions = []
            return
        }
        customSessions = decoded
    }
}
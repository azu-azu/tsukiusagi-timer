import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published private(set) var sessions: [SessionItem] = []

    // Convenience getters
    var fixedSessions: [SessionItem]  { sessions.filter { $0.isFixed } }
    var customSessions: [SessionItem] { sessions.filter { !$0.isFixed } }

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
        // 必要に応じて初期データ投入
        if sessions.isEmpty {
            sessions = SessionItem.fixedSessions
        }
    }

    // MARK: - CRUD
    func addSession(_ item: SessionItem) throws {
        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sessions.contains(where: { $0.name == trimmedName }) else {
            throw SessionError.duplicate
        }
        // カスタムのみ上限チェック（例: 50）
        if !item.isFixed && customSessions.count >= 50 {
            throw SessionError.limitExceeded
        }
        var newItem = item
        newItem.name = trimmedName
        newItem.subtitle = item.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        sessions.append(newItem)
        // save()
    }

    func editSession(id: UUID, newName: String, newSubtitle: String?) throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else {
            throw SessionError.notFound
        }
        // 重複チェック（自分以外）
        if sessions.contains(where: { $0.name == trimmedName && $0.id != id }) {
            throw SessionError.duplicate
        }
        sessions[idx].name = trimmedName
        sessions[idx].subtitle = newSubtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        // save()
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        // save()
    }
}
import Combine
import Foundation

@MainActor
class SessionManagerV2: ObservableObject {
    @Published private(set) var sessions: [SessionName] = []

    enum SessionError: Error, LocalizedError {
        case duplicate
        case limitExceeded
        case notFound

        var errorDescription: String? {
            switch self {
            case .duplicate:
                return "This session name is already registered."
            case .limitExceeded:
                return "You have reached the maximum number of sessions or subtitles."
            case .notFound:
                return "Session or subtitle not found."
            }
        }
    }

    func addSession(_ session: SessionName) throws {
        let trimmedName = session.name.normalized
        let key = SessionName(name: trimmedName).internalKey
        guard !sessions.contains(where: { $0.internalKey == key }) else {
            throw SessionError.duplicate
        }
        guard sessions.count < SessionName.parentLimit else {
            throw SessionError.limitExceeded
        }
        var newSession = session
        newSession.name = trimmedName
        sessions.append(newSession)
    }

    func addSubtitle(to sessionID: UUID, text: String) throws {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw SessionError.notFound
        }
        let trimmedText = text.normalized
        let session = sessions[idx]
        let newKey = Subtitle(text: trimmedText).internalKey
        guard session.subtitles.count < SessionName.childLimit else {
            throw SessionError.limitExceeded
        }
        guard !session.subtitles.contains(where: { $0.internalKey == newKey }) else {
            throw SessionError.duplicate
        }
        var updatedSession = session
        updatedSession.subtitles.append(Subtitle(text: trimmedText))
        sessions[idx] = updatedSession
    }

    func deleteSubtitle(sessionID: UUID, subtitleID: UUID) throws {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionID }) else {
            throw SessionError.notFound
        }
        var session = sessions[idx]
        guard let subIndex = session.subtitles.firstIndex(where: { $0.id == subtitleID }) else {
            throw SessionError.notFound
        }
        session.subtitles.remove(at: subIndex)
        sessions[idx] = session
    }

    func editSession(id: UUID, newName: String, newSubtitles: [String]) throws {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else {
            throw SessionError.notFound
        }
        let newKey = SessionName(name: newName.normalized).internalKey
        if sessions.contains(where: { $0.internalKey == newKey && $0.id != id }) {
            throw SessionError.duplicate
        }
        var updated = sessions[idx]
        updated.name = newName.normalized
        updated.subtitles = newSubtitles.map { Subtitle(text: $0.normalized) }.filter { !$0.text.isEmpty }
        sessions[idx] = updated
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
    }

    func migrateFromV2(_ oldSessions: [SessionItem]) -> [SessionName] {
        var seen = Set<String>()
        var result: [SessionName] = []
        for item in oldSessions {
            let key = item.name.normalized.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            let subtitles: [Subtitle]
            if let sub = item.subtitle, !sub.isEmpty {
                subtitles = [Subtitle(text: sub)]
            } else {
                subtitles = []
            }
            result.append(SessionName(id: item.id, name: item.name, subtitles: subtitles))
        }
        return result
    }

    func saveAsync() async throws {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: "customSessionsV3")
        } catch {
            print("❌ SaveAsync failed: \(error)")
            throw error
        }
    }

    func loadAsync() async throws {
        if let data = UserDefaults.standard.data(forKey: "customSessionsV3") {
            let decoded = try JSONDecoder().decode([SessionName].self, from: data)
            await MainActor.run { self.sessions = decoded }
        } else {
            await MainActor.run { self.sessions = [] }
        }
    }
}

#if DEBUG
extension SessionManagerV2 {
    static var previewData: SessionManagerV2 {
        let manager = SessionManagerV2()
        manager.sessions = [
            SessionName(name: "Sample Session 1", subtitles: [Subtitle(text: "Test subtitle")]),
            SessionName(name: "Sample Session 2", subtitles: [])
        ]
        return manager
    }
}
#endif

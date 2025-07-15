import Combine
import Foundation

class SessionManagerV2: ObservableObject {
    @Published var customEntries: [SessionEntry] = []
    let defaultEntries: [SessionEntry] = [
        SessionEntry(sessionName: "work"),
        SessionEntry(sessionName: "study"),
        SessionEntry(sessionName: "read")
    ]

    var allEntries: [SessionEntry] {
        defaultEntries + customEntries
    }

    init() {
        load()
    }

    func addEntry(sessionName: String?, subtitles: [String]) {
        guard (sessionName?.isEmpty != true) || !subtitles.allSatisfy({ $0.isEmpty }) else { return }
        let entry = SessionEntry(sessionName: sessionName, subtitles: subtitles)
        customEntries.append(entry)
        save()
    }

    func editEntry(id: UUID, sessionName: String?, subtitles: [String]) {
        guard let idx = customEntries.firstIndex(where: { $0.id == id }) else { return }
        customEntries[idx].sessionName = sessionName
        customEntries[idx].subtitles = subtitles
        save()
    }

    func deleteEntry(id: UUID) {
        customEntries.removeAll { $0.id == id }
        save()
    }

    private func save() {
        // UserDefaults等への保存処理（仮実装）
        if let data = try? JSONEncoder().encode(customEntries) {
            UserDefaults.standard.set(data, forKey: "customEntries")
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "customEntries"),
           let decoded = try? JSONDecoder().decode([SessionEntry].self, from: data) {
            self.customEntries = decoded
        } else {
            self.customEntries = []
        }
    }
}

#if DEBUG
extension SessionManagerV2 {
    static var previewData: SessionManagerV2 {
        let manager = SessionManagerV2()
        manager.customEntries = [
            SessionEntry(sessionName: "Sample Session 1", subtitles: ["Test subtitle"]),
            SessionEntry(sessionName: "Sample Session 2", subtitles: []),
            // サブタイトルが複数あるケース
            SessionEntry(sessionName: "Multi Subtitle Session", subtitles: [
                "First subtitle",
                "Second subtitle",
                "Third subtitle"
            ]),
            // サブタイトルが空のケース
            SessionEntry(sessionName: "No Subtitle Session", subtitles: []),
            // 長いセッション名
            SessionEntry(
                sessionName: "This is a very long session name to test how the UI handles overflow and wrapping in the list row",
                subtitles: [
                    "Long subtitle for testing purposes"
                ]
            ),
            // 特殊文字
            SessionEntry(
                sessionName: "Special!@#¥%&*()_+{}|:<>? Session",
                subtitles: [
                    "Emoji 😊🚀✨",
                    "Symbols #$%&"
                ]
            ),
            // 多件数テスト
            SessionEntry(sessionName: "Session 3", subtitles: []),
            SessionEntry(sessionName: "Session 4", subtitles: []),
            SessionEntry(sessionName: "Session 5", subtitles: []),
            SessionEntry(sessionName: "Session 6", subtitles: []),
            SessionEntry(sessionName: "Session 7", subtitles: [])
        ]
        return manager
    }
}
#endif

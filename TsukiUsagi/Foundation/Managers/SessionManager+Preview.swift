import Foundation

/// SessionManagerのプレビュー用データ拡張
///
/// 責務:
/// - デバッグ用のサンプルデータ生成
/// - プレビュー環境での動作確認
/// - テスト用データのセットアップ
#if DEBUG
extension SessionManager {
    /// プレビュー用のSessionManagerインスタンス
    static var previewData: SessionManager {
        let manager = SessionManager()
        let samples: [SessionEntry] = [
            SessionEntry(
                sessionName: "Sample Session 1",
                tasks: ["Test task"],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Sample Session 2",
                tasks: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Multi Task Session",
                tasks: [
                    "First task",
                    "Second task",
                    "Third task"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "No Task Session",
                tasks: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName:
                    "This is a very long session name to test how the UI handles overflow " +
                    "and wrapping in the list row",
                tasks: [
                    "Long task for testing purposes"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Special!@#¥%&*()_+{}|:<>? Session",
                tasks: ["Emoji 😊🚀✨", "Symbols #$%&"],
                isDefault: false
            ),
            SessionEntry(sessionName: "Session 3", tasks: [], isDefault: false),
            SessionEntry(sessionName: "Session 4", tasks: [], isDefault: false),
            SessionEntry(sessionName: "Session 5", tasks: [], isDefault: false),
            SessionEntry(sessionName: "Session 6", tasks: [], isDefault: false),
            SessionEntry(sessionName: "Session 7", tasks: [], isDefault: false)
        ]

        // サンプルデータをデータベースに追加
        for entry in samples {
            let key = entry.sessionName
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            manager.sessionDatabase[key] = entry
        }

        return manager
    }
}
#endif

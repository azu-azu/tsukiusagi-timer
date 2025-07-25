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
                descriptions: ["Test description"],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Sample Session 2",
                descriptions: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Multi Description Session",
                descriptions: [
                    "First description",
                    "Second description",
                    "Third description"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "No Description Session",
                descriptions: [],
                isDefault: false
            ),
            SessionEntry(
                sessionName:
                    "This is a very long session name to test how the UI handles overflow " +
                    "and wrapping in the list row",
                descriptions: [
                    "Long description for testing purposes"
                ],
                isDefault: false
            ),
            SessionEntry(
                sessionName: "Special!@#¥%&*()_+{}|:<>? Session",
                descriptions: ["Emoji 😊🚀✨", "Symbols #$%&"],
                isDefault: false
            ),
            SessionEntry(sessionName: "Session 3", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 4", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 5", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 6", descriptions: [], isDefault: false),
            SessionEntry(sessionName: "Session 7", descriptions: [], isDefault: false)
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

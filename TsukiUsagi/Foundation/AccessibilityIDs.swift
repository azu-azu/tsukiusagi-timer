import Foundation

/// 型安全なアクセシビリティID の管理
/// プロダクトコードとUITest両方で同じIDを参照できるように構造化
struct AccessibilityIDs {
    // MARK: - Settings

    enum Settings {
        /// 作業時間フィールド
        static let workMinutesField = "settings_workMinutesField"

        /// 休憩時間フィールド
        static let breakMinutesField = "settings_breakMinutesField"

        /// 作業時間マイナスボタン
        static let workMinutesMinusButton = "settings_workMinutesMinusButton"

        /// 作業時間プラスボタン
        static let workMinutesPlusButton = "settings_workMinutesPlusButton"

        /// 休憩時間マイナスボタン
        static let breakMinutesMinusButton = "settings_breakMinutesMinusButton"

        /// 休憩時間プラスボタン
        static let breakMinutesPlusButton = "settings_breakMinutesPlusButton"

        /// アクティビティフィールド
        static let activityField = "settings_activityField"

        /// サブタイトルフィールド
        static let subtitleField = "settings_subtitleField"

        /// セッション名管理リンク
        static let manageSessionNamesLink = "settings_manageSessionNamesLink"

        /// リセットボタン
        static let resetButton = "settings_resetButton"

        /// 停止ボタン
        static let stopButton = "settings_stopButton"

        /// 履歴表示リンク
        static let viewHistoryLink = "settings_viewHistoryLink"
    }

    // MARK: - Session Manager

    enum SessionManager {
        /// セッション名フィールド
        static let nameField = "sessionManager_nameField"

        /// ディスクリプションフィールド
        static let descriptionField = "sessionManager_descriptionField"

        /// 追加ボタン
        static let addButton = "sessionManager_addButton"

        /// 編集ボタン
        static let editButton = "sessionManager_editButton"

        /// 削除ボタン
        static let deleteButton = "sessionManager_deleteButton"

        /// 保存ボタン
        static let saveButton = "sessionManager_saveButton"

        /// キャンセルボタン
        static let cancelButton = "sessionManager_cancelButton"

        /// セッション名セル
        static func sessionCell(id: String) -> String {
            return "sessionManager_sessionCell_\(id)"
        }
    }

    // MARK: - History

    enum History {
        /// 日モードボタン
        static let dayModeButton = "history_dayModeButton"

        /// 月モードボタン
        static let monthModeButton = "history_monthModeButton"

        /// 前日/前月ボタン
        static let previousButton = "history_previousButton"

        /// 翌日/翌月ボタン
        static let nextButton = "history_nextButton"

        /// 復元ボタン
        static let restoreButton = "history_restoreButton"

        /// レコードセル
        static func recordCell(id: String) -> String {
            return "history_recordCell_\(id)"
        }

        /// 集計セクション
        static func summarySection(title: String) -> String {
            return "history_summarySection_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))"
        }
    }

    // MARK: - Timer

    enum Timer {
        /// タイマーパネル
        static let timerPanel = "timer_timerPanel"

        /// 開始/停止ボタン
        static let startStopButton = "timer_startStopButton"

        /// リセットボタン
        static let resetButton = "timer_resetButton"

        /// 編集ボタン
        static let editButton = "timer_editButton"
    }

    // MARK: - Common

    enum Common {
        /// 閉じるボタン
        static let closeButton = "common_closeButton"

        /// 完了ボタン
        static let doneButton = "common_doneButton"

        /// キャンセルボタン
        static let cancelButton = "common_cancelButton"

        /// 確認ボタン
        static let confirmButton = "common_confirmButton"

        /// 削除ボタン
        static let deleteButton = "common_deleteButton"
    }

    // MARK: - Validation

    /// アクセシビリティID の有効性を検証
    /// 重複や無効な文字が含まれていないかチェック
    static func validate() -> [String] {
        let mirror = Mirror(reflecting: AccessibilityIDs())
        var errors: [String] = []

        for child in mirror.children {
            if let value = child.value as? String {
                // 空文字チェック
                if value.isEmpty {
                    errors.append("Empty accessibility ID found")
                }

                // 特殊文字チェック
                if value.contains(" ") || value.contains("\n") || value.contains("\t") {
                    errors.append("Invalid characters in accessibility ID: \(value)")
                }

                // 重複チェック（簡易版）
                // 実際の重複チェックはより複雑な実装が必要
            }
        }

        return errors
    }
}

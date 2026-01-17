// UIに表示される名称・見出し・項目名・状態名などの“名札”。短く、文にならないもの。
// 何者かの名前・見出し・項目名・状態名（名詞/名詞句、コロン付き行ラベル含む）

// 詳細： _guide-copy-classification.md 参照

import Foundation

enum Labels {
    enum Sections {
        static let sessionManagement = "session_management_title".localized
        static let defaultSessions = "default_sessions_title".localized
        static let customSessions = "custom_sessions_title".localized
        static let editTasks = "edit_tasks_title".localized
        static let editSession = "edit_session_title".localized
        static let deleteSession = "delete_session_title".localized
        static let newCustomSession = "new_custom_session_title".localized
        static let createCustomSession = "create_custom_session_title".localized
        static let sessionLabel = "timer_edit_session_label_section_title".localized
        static let finalTime = "timer_edit_final_time_title".localized
        static let editRecord = "timer_edit_record_title".localized
        static let sessionInfo = "history_memo_session_info".localized
        static let reflection = "reflection_title".localized
        static let settingsDurationAndSession = "settings_duration_session_settings".localized
        static let addReflection = "history_memo_add_reflection".localized
        static let editReflection = "history_memo_edit_reflection".localized
    }

    enum InfoRow {
        static let sessionName = "session_name_label".localized
        static let tasks = "tasks_label".localized
        static let defaultSession = "default_session_label".localized
        static let customSession = "custom_session_label".localized
        static let sessionNameRequired = "session_name_required_label".localized
        static let tasksOptional = "tasks_optional_label".localized
        static let historyMode = "history_picker_label".localized
        static let session = "history_memo_session".localized
        static let task = "history_memo_task".localized
        static let duration = "history_memo_duration".localized
        static let reflection = "history_memo_reflection".localized
    }

    enum State {
        static let noTask = "session_task_none".localized
        static let noTasksConfigured = "session_task_none_available".localized
        static let noRecordsForThisDay = "history_detail_no_records".localized
        static let readOnly = "settings_read_only".localized
    }

    enum Settings {
        static let manageSessionNames = "settings_manage_session_names".localized
    }
}

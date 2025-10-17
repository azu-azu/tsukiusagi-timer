// UIに表示される名称・見出し・項目名・状態名などの“名札”。短く、文にならないもの。
// 何者かの名前・見出し・項目名・状態名（名詞/名詞句、コロン付き行ラベル含む）

// 詳細： _guide-copy-classification.md 参照

import Foundation

enum Labels {
    enum Sections {
        static let sessionManagement = NSLocalizedString("session_management_title", comment: "Session Management")
        static let defaultSessions = NSLocalizedString("default_sessions_title", comment: "Default Sessions")
        static let customSessions = NSLocalizedString("custom_sessions_title", comment: "Custom Sessions")
        static let editTasks = NSLocalizedString("edit_tasks_title", comment: "Edit Tasks")
        static let editSession = NSLocalizedString("edit_session_title", comment: "Edit Session")
        static let deleteSession = NSLocalizedString("delete_session_title", comment: "Delete Session")
        static let newCustomSession = NSLocalizedString("new_custom_session_title", comment: "New Custom Session")
        static let createCustomSession = NSLocalizedString(
            "create_custom_session_title",
            comment: "Create Custom Session"
        )
        static let sessionLabel = NSLocalizedString("timer_edit_session_label_section_title", comment: "Session Label")
        static let finalTime = NSLocalizedString("timer_edit_final_time_title", comment: "Final Time")
        static let editRecord = NSLocalizedString("timer_edit_record_title", comment: "Edit Record")
        static let sessionInfo = NSLocalizedString("history_memo_session_info", comment: "Session Info")
        static let reflection = NSLocalizedString("reflection_title", comment: "Reflection")
        static let settingsDurationAndSession = NSLocalizedString(
            "settings_duration_session_settings",
            comment: "Duration & Session Settings View"
        )
        static let addReflection = NSLocalizedString("history_memo_add_reflection", comment: "Add reflection title")
        static let editReflection = NSLocalizedString("history_memo_edit_reflection", comment: "Edit reflection title")
    }

    enum InfoRow {
        static let sessionName = NSLocalizedString("session_name_label", comment: "Session Name")
        static let tasks = NSLocalizedString("tasks_label", comment: "Tasks")
        static let defaultSession = NSLocalizedString("default_session_label", comment: "Default Session")
        static let customSession = NSLocalizedString("custom_session_label", comment: "Custom Session")
        static let sessionNameRequired = NSLocalizedString("session_name_required_label", comment: "Session Name *")
        static let tasksOptional = NSLocalizedString("tasks_optional_label", comment: "Tasks (Optional)")
        static let historyMode = NSLocalizedString("history_picker_label", comment: "History Mode")
        static let session = NSLocalizedString("history_memo_session", comment: "Session:")
        static let task = NSLocalizedString("history_memo_task", comment: "Task:")
        static let duration = NSLocalizedString("history_memo_duration", comment: "Duration:")
        static let reflection = NSLocalizedString("history_memo_reflection", comment: "Reflection")
    }

    enum State {
        static let noTask = NSLocalizedString("session_task_none", comment: "No task")
        static let noTasksConfigured = NSLocalizedString("session_task_none_available", comment: "No tasks configured")
        static let noCustomSessionsYet = NSLocalizedString(
            "empty_custom_sessions_title",
            comment: "No custom sessions yet"
        )
        static let noRecordsForThisDay = NSLocalizedString(
            "history_detail_no_records",
            comment: "No records for this day"
        )
        static let readOnly = NSLocalizedString("settings_read_only", comment: "READ-ONLY")
    }

    enum Settings {
        static let manageSessionNames = NSLocalizedString("settings_manage_session_names", comment: "Manage sessions")
    }
}

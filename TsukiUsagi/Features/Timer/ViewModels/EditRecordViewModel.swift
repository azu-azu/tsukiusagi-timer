//
//  EditRecordViewModel.swift
//  TsukiUsagi
//
//  Created by Azu on 2025/01/01.
//

import SwiftUI
import Combine

/// EditRecordViewの状態管理とビジネスロジックを担当するViewModel
@MainActor
final class EditRecordViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var editedActivity = ""
    @Published var editedTask = ""
    @Published var editedMemo = ""
    @Published var editedEnd = Date()
    @Published var minEnd = Date()
    @Published var isKeyboardVisible: Bool = false
    @Published var keyboardBottomInset: CGFloat = 0
    @Published var isAutoScrolling: Bool = false

    // MARK: - FocusState Properties

    @FocusState var isTaskFocused: Bool
    @FocusState var isMemoFocused: Bool
    @FocusState var isActivityFocused: Bool

    // MARK: - Computed Properties

    /// カスタムアクティビティかどうかを判定
    var isCustomActivity: Bool {
        let predefinedActivities = ["Work", "Study", "Read"]
        return !predefinedActivities.contains { $0.lowercased() == editedActivity.lowercased() }
    }

    /// Memoエディタの最大高さ（常に有限かつmin以上にクランプ）
    var memoEditorMaxHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let candidate = (screenHeight.isFinite && screenHeight > 0) ? screenHeight * 0.4 : 300
        return max(120, candidate)
    }

    /// safeAreaInset用のボトム余白（負・非有限を排除）
    var bottomInsetForSafeArea: CGFloat {
        let inset = isKeyboardVisible ? keyboardBottomInset : 0
        if inset.isFinite && inset >= 0 { return inset }
        return 0
    }

    // MARK: - Validation Methods

    /// アクティビティが空かどうかを判定
    func isActivityEmpty() -> Bool {
        return editedActivity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 保存ボタンを無効化すべきかどうかを判定
    func shouldDisableSave() -> Bool {
        return isActivityEmpty()
    }

    // MARK: - Initialization

    init() {
        // 初期化処理
    }

    // MARK: - Public Methods

    /// 編集データを初期化
    func initializeEditData(activity: String, task: String, memo: String, end: Date) {
        editedActivity = activity
        editedTask = task
        editedMemo = memo
        editedEnd = end
        minEnd = end
    }

    /// キーボード表示状態を更新
    func updateKeyboardState(isVisible: Bool, bottomInset: CGFloat) {
        isKeyboardVisible = isVisible
        keyboardBottomInset = bottomInset
    }

    /// 自動スクロール状態を更新
    func updateAutoScrollingState(_ isScrolling: Bool) {
        isAutoScrolling = isScrolling
    }
}

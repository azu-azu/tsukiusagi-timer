import SwiftUI

struct TimerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    // 新しいViewModelとBuilder（既存コードと並行動作）
    @StateObject private var editViewModel = TimerEditViewModel()
    private let sectionBuilder = TimerEditSectionBuilder()

    // 既存のプロパティ（後方互換性のため保持）
    @State private var editedActivity = ""
    @State private var editedTask = ""
    @State private var editedMemo = ""
    @State private var editedEnd = Date()
    @State private var minEnd = Date()
    @FocusState private var isTaskFocused: Bool
    @FocusState private var isMemoFocused: Bool
    // スクロール位置制御用の識別子（小さなアンカー用）
    private enum SectionID: Hashable { case memoAnchor }
    @FocusState private var isActivityFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?
    @State private var memoAnchorGlobalMaxY: CGFloat = 0
    @State private var keyboardEndFrame: CGRect = .zero
    @State private var bottomLiftPadding: CGFloat = 0

    // SettingsViewと同じ定数
    private let topPadding: CGFloat = 8
    private let cardCornerRadius: CGFloat = 8
    private let labelCornerRadius: CGFloat = 6

    // 既存の計算プロパティ（新しいViewModelに委譲）
    private var isCustomActivity: Bool {
        return editViewModel.isCustomActivity
    }

    // Memoエディタの最大高さ（新しいViewModelに委譲）
    private var memoEditorMaxHeight: CGFloat {
        return editViewModel.memoEditorMaxHeight
    }

    // バリデーション関数（新しいViewModelに委譲）
    private func isActivityEmpty() -> Bool {
        return editViewModel.isActivityEmpty()
    }

    private func shouldDisableSave() -> Bool {
        return editViewModel.shouldDisableSave()
    }

    // リアルタイムでエラー状態を計算
    private var currentShowEmptyError: Bool {
        return isCustomActivity && isActivityEmpty()
    }

    @MainActor private func closeKeyboard() {
        isActivityFocused = false
        isTaskFocused = false
        isMemoFocused = false
        Keyboard.dismiss()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景（画面全体、clipされない）
                DesignTokens.CosmosColors.background.ignoresSafeArea()

                // SettingsViewと同じ構造に統一
                VStack(spacing: 0) {
                    // ヘッダーを固定位置に配置（SettingsViewと同じ構造）
                    TimerEditHeaderView(
                        editedActivity: editedActivity,
                        editedTask: editedTask,
                        editedMemo: editedMemo,
                        editedEnd: editedEnd,
                        isSaveDisabledExtra: isNoChanges
                    )
                    .background(DesignTokens.CosmosColors.background)
                    .zIndex(1)

                    // スクロール可能なコンテンツ
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                            // Session Label
                            sectionBuilder.section(
                                title: NSLocalizedString(
                                    "timer_edit_session_label_section_title",
                                    comment: "Title for session label section"
                                ),
                                isCompact: true
                            ) {
                                SessionLabelSection(
                                    activity: $editedActivity,
                                    taskText: $editedTask,
                                    isActivityFocused: $isActivityFocused,
                                    isTaskFocused: $isTaskFocused,
                                    labelCornerRadius: labelCornerRadius,
                                    showEmptyError: .constant(currentShowEmptyError),
                                    onDone: nil
                                )
                            }

                            // Final Time
                            sectionBuilder.section(title: "", isCompact: true) {
                                DatePicker(
                                    NSLocalizedString(
                                        "timer_edit_final_time_title",
                                        comment: "Label for the final time picker"
                                    ),
                                    selection: $editedEnd,
                                    in: minEnd...,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .padding(.horizontal, 8)
                                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                                .colorScheme(.dark)
                            }

                            // Reflect
                            sectionBuilder.section(title: Copy.Reflection.title, isCompact: true) {
                                TextEditor(text: $editedMemo)
                                    .frame(minHeight: 220, maxHeight: memoEditorMaxHeight)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .background(DesignTokens.WhiteColors.surface)
                                    .cornerRadius(6)
                                    .focused($isMemoFocused)
                                    .overlay(
                                        // プレースホルダー
                                        Group {
                                            if editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(Copy.Reflection.placeholder)
                                                            .font(DesignTokens.Fonts.caption)
                                                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                                                        Spacer()
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 12)
                                                .allowsHitTesting(false)
                                            }
                                        }
                                    )

                                // TextEditor直下に小さなアンカーを置く
                                Color.clear
                                    .frame(height: 1)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: MemoAnchorPreferenceKey.self,
                                                value: geo.frame(in: .global).maxY
                                            )
                                        }
                                    )
                                    .id(SectionID.memoAnchor)
                            }

                            // 可変の下パディングでキーボード回避を行うため、固定Spacerは不要
                            }
                            .padding()
                            .padding(.bottom, bottomLiftPadding)
                            // ScrollViewの中での下余白は最小限に留める（主にsafeAreaInsetで担保）
                        }
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden) // スクロールインジケーター非表示
                        .scrollDismissesKeyboard(.interactively)
                        .scrollBounceBehavior(.basedOnSize) // バウンス動作を制御
                        .dismissKeyboardOnTap { closeKeyboard() }
                        .onAppear { scrollProxy = proxy }
                        .onChange(of: isMemoFocused) { _, focused in
                            if focused {
                                guard keyboardEndFrame.height > 0, let proxy = scrollProxy else { return }
                                ensureMemoVisibleOnce(using: proxy)
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    bottomLiftPadding = 0
                                }
                            }
                        }
                        .onReceive(
                            NotificationCenter.default.publisher(
                                for: UIResponder.keyboardDidChangeFrameNotification
                            )
                        ) { notification in
                            if let userInfo = notification.userInfo,
                               let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                                keyboardEndFrame = frameValue.cgRectValue
                            }
                            guard isMemoFocused, let proxy = scrollProxy else { return }
                            ensureMemoVisibleOnce(using: proxy)
                        }
                        .onPreferenceChange(MemoAnchorPreferenceKey.self) { maxY in
                            memoAnchorGlobalMaxY = maxY
                        }
                    }
                }
                // 角丸クリップを外し、シートの下地色が見えないようにする
                .presentationDetents([.large])
            }
            .navigationBarHidden(true) // NavigationBarを非表示
            // システムのセーフエリア調整を使う（競合を避けるためキーボード無視は外す）
            // シートの背景そのものを黒系テーマに統一
            .presentationBackground(DesignTokens.CosmosColors.background)
            .background(DesignTokens.CosmosColors.background) // 万一の透過対策
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(DesignTokens.CosmosColors.background, for: .navigationBar)
            .keyboardCloseToolbar(
                labelStyle: .iconWithText(
                    NSLocalizedString(
                        "keyboard_close_button",
                        comment: "Toolbar button to close the keyboard"
                    )
                )
            ) {
                closeKeyboard()
            }
            .onDisappear {
                closeKeyboard()
            }
            .task {
                // 編集対象は「最後に記録された履歴」なので、History から初期値を読み込む
                if let last = historyVM.history.last {
                    editedEnd = last.end
                    minEnd = last.start
                    editedActivity = last.sessionName
                    editedTask = last.task ?? ""
                    editedMemo = last.memo ?? ""
                } else {
                    // フォールバック（念のため）
                    editedEnd = timerVM.endTime ?? Date()
                    minEnd = timerVM.startTime ?? Date()
                    editedActivity = timerVM.activityLabel.isEmpty ? "Work" : timerVM.activityLabel
                    editedTask = timerVM.taskLabel
                    editedMemo = ""
                }
            }
            // 保存系のアクションはヘッダー内のボタンで行われる想定
            // 保存成功時のフィードバックと閉じ処理を注入
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TimerEditSaved"))) { _ in
                HapticManager.shared.buttonTapFeedback()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                // 微遅延で閉じる（0.1s）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                    dismiss()
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: NSLocalizedString(
                            "timer_edit_saved_announcement",
                            comment: "Announcement when timer edit is saved"
                        )
                    )
                }
            }
            // Reset通知を受けて元の値に戻す（UIはWYSIWYGで即時反映）
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TimerEditReset"))) { _ in
                HapticManager.shared.buttonTapFeedback()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let last = historyVM.history.last {
                    editedEnd = last.end
                    minEnd = last.start
                    editedActivity = last.sessionName
                    editedTask = last.task ?? ""
                    editedMemo = last.memo ?? ""
                } else {
                    editedEnd = timerVM.endTime ?? Date()
                    minEnd = timerVM.startTime ?? Date()
                    editedActivity = timerVM.activityLabel.isEmpty ? "Work" : timerVM.activityLabel
                    editedTask = timerVM.taskLabel
                    editedMemo = ""
                }
                UIAccessibility.post(
                    notification: .announcement,
                    argument: NSLocalizedString(
                        "timer_edit_reset_announcement",
                        comment: "Announcement when timer edit resets to original values"
                    )
                )
            }
        }
    }

    // section関数は削除（TimerEditSectionBuilderを使用）
}

// MARK: - Change detection
private extension TimerEditView {
    struct MemoAnchorPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    func ensureMemoVisibleOnce(using _: ScrollViewProxy) {
        guard keyboardEndFrame.height > 0 else {
            withAnimation(.easeInOut(duration: 0.2)) { bottomLiftPadding = 0 }
            return
        }

        let keyboardTop = keyboardEndFrame.minY
        guard keyboardTop > 0 else {
            withAnimation(.easeInOut(duration: 0.2)) { bottomLiftPadding = 0 }
            return
        }

        let overlap = memoAnchorGlobalMaxY - keyboardTop
        let needed = max(0, overlap + 16)

        withAnimation(.easeInOut(duration: 0.2)) {
            bottomLiftPadding = needed
        }
    }

    var isNoChanges: Bool {
        // 比較元も履歴の最後のレコードを参照（なければVMの値でフォールバック）
        let originalActivity = historyVM.history.last?.sessionName
            ?? (timerVM.activityLabel.isEmpty ? "Work" : timerVM.activityLabel)
        let originalTask = historyVM.history.last?.task
            ?? timerVM.taskLabel
        let originalMemo = historyVM.history.last?.memo ?? ""
        let originalEnd = historyVM.history.last?.end ?? (timerVM.endTime ?? Date())
        let activitySame = editedActivity.trimmingCharacters(in: .whitespacesAndNewlines) == originalActivity
        let taskSame = editedTask.trimmingCharacters(in: .whitespacesAndNewlines) == originalTask
        // 分解能は分単位で比較（秒の僅差での誤判定を避ける）
        let cal = Calendar.current
        let comps1 = cal.dateComponents([.hour, .minute], from: editedEnd)
        let comps2 = cal.dateComponents([.hour, .minute], from: originalEnd)
        let endSame = comps1.hour == comps2.hour && comps1.minute == comps2.minute
        let memoSame = editedMemo.trimmingCharacters(in: .whitespacesAndNewlines)
            == originalMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        return activitySame && taskSame && endSame && memoSame
    }
}

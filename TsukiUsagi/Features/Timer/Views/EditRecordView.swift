import SwiftUI

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    // 新しいViewModelとBuilder（既存コードと並行動作）
    @StateObject private var editViewModel = EditRecordViewModel()
    private let sectionBuilder = EditRecordSectionBuilder()

    // 既存のプロパティ（後方互換性のため保持）
    @State private var editedActivity = ""
    @State private var editedTask = ""
    @State private var editedMemo = ""
    @State private var editedEnd = Date()
    @State private var minEnd = Date()
    @FocusState private var isTaskFocused: Bool
    @FocusState private var isMemoFocused: Bool
    @FocusState private var isActivityFocused: Bool
    @State private var showMemoSheet: Bool = false
    @State private var showReflectionInput: Bool = false

    // 既存の計算プロパティ（新しいViewModelに委譲）
    private var isCustomActivity: Bool {
        return editViewModel.isCustomActivity
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
        showReflectionInput = false
        Keyboard.dismiss()
    }

    var body: some View {
        NavigationStack {
            // SettingsViewと同じ構造に統一
            VStack(spacing: 0) {
                headerView
                scrollContainer
            }
            // Bottom: チャット風入力バー or リセットボタン
            .safeAreaInset(edge: .bottom) {
                if showReflectionInput {
                    BottomInputBar(
                        text: $editedMemo,
                        isFocused: $isMemoFocused,
                        placeholder: LocalizedStringKey("reflection_placeholder"),
                        onExpand: {
                            isMemoFocused = false
                            showReflectionInput = false
                            showMemoSheet = true
                        }
                    )
                } else {
                    resetBar
                }
            }
            // 背景（画面全体、セーフエリアを含む）- TsukiSound風グラデーション
            .background(DesignTokens.SkyToneColors.backgroundGradient.ignoresSafeArea())
            .navigationBarHidden(true) // NavigationBarを非表示
            // シートの背景そのものを黒系テーマに統一
            .presentationDetents([.large])
            .presentationBackground(DesignTokens.SkyToneColors.nightStart)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(DesignTokens.CosmosColors.background, for: .navigationBar)
            .keyboardCloseToolbar(
                labelStyle: .iconWithText(Copy.Button.close)
            ) {
                closeKeyboard()
            }
            .onDisappear {
                closeKeyboard()
            }
            .sheet(isPresented: $showMemoSheet) { memoSheetView }
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
                        argument: Copy.Label.saved
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
                    argument: LocalizedStringKey("timer_edit_reset_announcement")
                )
            }
        }
    }

    // section関数は削除（EditRecordSectionBuilderを使用）
}

// MARK: - Change detection
private extension EditRecordView {
    @ViewBuilder
    var headerView: some View {
        EditRecordHeaderView(
            editedActivity: editedActivity,
            editedTask: editedTask,
            editedMemo: editedMemo,
            editedEnd: editedEnd,
            isSaveDisabledExtra: isNoChanges
        )
        .background(DesignTokens.SkyToneColors.nightStart)
        .zIndex(1)
    }

    @ViewBuilder
    var scrollContainer: some View {
        ScrollView { scrollContent }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            .dismissKeyboardOnTap { closeKeyboard() }
    }

    @ViewBuilder
    var scrollContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            sessionLabelSection
            finalTimeSection
            reflectionSection
        }
        .padding()
    }

    @ViewBuilder
    var sessionLabelSection: some View {
        sectionBuilder.section(
            title: Labels.Sections.sessionLabel,
            isHighlight: true
        ) {
            SessionLabelSection(
                activity: $editedActivity,
                taskText: $editedTask,
                isActivityFocused: $isActivityFocused,
                isTaskFocused: $isTaskFocused,
                showEmptyError: .constant(currentShowEmptyError),
                onDone: nil
            )
        }
    }

    @ViewBuilder
    var finalTimeSection: some View {
        sectionBuilder.section(title: "") {
            DatePicker(
                Labels.Sections.finalTime,
                selection: $editedEnd,
                in: minEnd...,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.compact)
            .padding(.horizontal, 8)
            .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
            .colorScheme(.dark)
        }
    }

    @ViewBuilder
    var reflectionSection: some View {
        sectionBuilder.section(
            title: ""
        ) {
            Text(Labels.Sections.reflection)
                .font(DesignTokens.Fonts.sectionTitle)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

            EditablePlaceholderCard(
                text: editedMemo,
                placeholder: LocalizedStringKey("reflection_placeholder"),
                isEditing: showReflectionInput,
                onTap: {
                    showReflectionInput = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isMemoFocused = true
                    }
                }
            )
        }
    }
    @ViewBuilder
    var resetBar: some View {
        HStack {
            Spacer()
            Button {
                NotificationCenter.default.post(name: Notification.Name("TimerEditReset"), object: nil)
            } label: {
                Label(Copy.Button.reset, systemImage: "arrow.uturn.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            .accessibilityIdentifier("resetEditedRecordButton")
            .accessibilityLabel(LocalizedStringKey("timer_edit_reset_a11y"))
            .accessibilityHint(LocalizedStringKey("timer_edit_reset_hint"))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    var memoSheetView: some View {
        LargeTextEditorSheet(
            text: $editedMemo,
            title: Labels.Sections.reflection,
            placeholder: LocalizedStringKey("reflection_placeholder"),
            onClose: { showMemoSheet = false }
        )
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

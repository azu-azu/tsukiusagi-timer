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
    // スクロール位置制御用の識別子（小さなアンカー用）
    private enum SectionID: Hashable { case memoAnchor }
    @FocusState private var isActivityFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?
    @State private var memoAnchorGlobalMaxY: CGFloat = 0
    @State private var keyboardEndFrame: CGRect = .zero
    @State private var bottomLiftPadding: CGFloat = 0
    @State private var showMemoSheet: Bool = false

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
            // SettingsViewと同じ構造に統一
            VStack(spacing: 0) {
                headerView
                scrollContainer
            }
            // Bottom reset control in safe area inset to avoid mis-tap near Save
            .safeAreaInset(edge: .bottom) { resetBar }
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
        ScrollViewReader { proxy in
            ScrollView { scrollContent }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)
                .dismissKeyboardOnTap { closeKeyboard() }
                .onAppear { scrollProxy = proxy }
                .onChange(of: isMemoFocused) { _, focused in
                    if focused {
                        guard keyboardEndFrame.height > 0, let proxy = scrollProxy else { return }
                        ensureMemoVisibleOnce(using: proxy)
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) { bottomLiftPadding = 0 }
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification)
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

    @ViewBuilder
    var scrollContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            sessionLabelSection
            finalTimeSection
            reflectionSection
        }
        .padding()
        .padding(.bottom, bottomLiftPadding)
    }

    @ViewBuilder
    var sessionLabelSection: some View {
        sectionBuilder.section(
            title: Labels.Sections.sessionLabel,
            isCompact: true,
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
        sectionBuilder.section(title: "", isCompact: true) {
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
            title: "",
            isCompact: true
        ) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(Labels.Sections.reflection)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                Spacer()
                ExpandIconButton(accessibilityIdentifier: "open_memo_sheet_button") {
                    isMemoFocused = false
                    showMemoSheet = true
                }
            }

            TextEditor(text: $editedMemo)
                .frame(minHeight: 220, maxHeight: memoEditorMaxHeight)
                .padding(12)
                .scrollContentBackground(.hidden)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                )
                .focused($isMemoFocused)
                .overlay(
                    Group {
                        if editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey("reflection_placeholder"))
                                        .font(DesignTokens.Fonts.label)
                                        .foregroundColor(DesignTokens.SkyToneColors.textQuinary)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                        }
                    }
                )

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

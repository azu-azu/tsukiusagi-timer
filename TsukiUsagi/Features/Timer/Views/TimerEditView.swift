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
    @State private var editedSubtitle = ""
    @State private var editedMemo = ""
    @State private var editedEnd = Date()
    @State private var minEnd = Date()
    @State private var isKeyboardVisible: Bool = false
    @State private var keyboardBottomInset: CGFloat = 0
    @State private var isAutoScrolling: Bool = false

    @FocusState private var isSubtitleFocused: Bool
    @FocusState private var isMemoFocused: Bool
    // スクロール位置制御用の識別子（小さなアンカー用）
    private enum SectionID: Hashable { case memoAnchor }
    @FocusState private var isActivityFocused: Bool

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

    // safeAreaInset用のボトム余白（新しいViewModelに委譲）
    private var bottomInsetForSafeArea: CGFloat {
        return editViewModel.bottomInsetForSafeArea
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
                        editedSubtitle: editedSubtitle,
                        editedMemo: editedMemo,
                        editedEnd: editedEnd,
                        isSaveDisabledExtra: isNoChanges
                    )
                    .background(DesignTokens.CosmosColors.background)
                    .zIndex(1)

                    // スクロール可能なコンテンツ
                    ScrollViewReader { _ in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                            // Session Label
                            sectionBuilder.section(title: "Session Label", isCompact: true) {
                                SessionLabelSection(
                                    activity: $editedActivity,
                                    descriptionText: $editedSubtitle,
                                    isActivityFocused: $isActivityFocused,
                                    isDescriptionFocused: $isSubtitleFocused,
                                    labelCornerRadius: labelCornerRadius,
                                    showEmptyError: .constant(currentShowEmptyError),
                                    onDone: nil
                                )
                            }

                            // Final Time
                            sectionBuilder.section(title: "Final Time", isCompact: true) {
                                DatePicker(
                                    "Final Time",
                                    selection: $editedEnd,
                                    in: minEnd...,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                                .colorScheme(.dark)
                            }

                            // Reflect
                            sectionBuilder.section(title: "Reflect", isCompact: true) {
                                TextEditor(text: $editedMemo)
                                    .frame(minHeight: 120, maxHeight: memoEditorMaxHeight)
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
                                                        Text("Reflect")
                                                            .font(DesignTokens.Fonts.label)
                                                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                                                        Text("Write anything you feel")
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
                                    .id(SectionID.memoAnchor)
                            }

                            Spacer(minLength: 40)
                            }
                            .padding()
                            // ScrollViewの中での下余白は最小限に留める（主にsafeAreaInsetで担保）
                        }
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden) // スクロールインジケーター非表示
                        .scrollDismissesKeyboard(.never) // 競合回避のため一旦無効化
                        .scrollBounceBehavior(.basedOnSize) // バウンス動作を制御
                        .safeAreaInset(edge: .bottom) {
                            // セーフエリア外まで背景を広げているため、
                            // 下端の余白は safeAreaInset で作るのが安定
                            Color.clear.frame(height: bottomInsetForSafeArea)
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
            .modifier(DismissKeyboardOnTap(
                isActivityFocused: $isActivityFocused,
                isSubtitleFocused: $isSubtitleFocused,
                isMemoFocused: $isMemoFocused,
                isKeyboardVisible: $isKeyboardVisible
            ))
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isKeyboardVisible = true
                }
                if let info = (notif as Notification).userInfo,
                    let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    let screenMaxY = UIScreen.main.bounds.maxY
                    let overlap = max(0, screenMaxY - frame.minY)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        keyboardBottomInset = overlap
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isKeyboardVisible = false
                    keyboardBottomInset = 0
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Close") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isActivityFocused = false
                            isSubtitleFocused = false
                            isMemoFocused = false
                            isKeyboardVisible = false
                        }
                    }
                }
            }
            .task {
                // 編集対象は「最後に記録された履歴」なので、History から初期値を読み込む
                if let last = historyVM.history.last {
                    editedEnd = last.end
                    minEnd = last.start
                    editedActivity = last.sessionName
                    editedSubtitle = last.description ?? ""
                    editedMemo = last.memo ?? ""
                } else {
                    // フォールバック（念のため）
                    editedEnd = timerVM.endTime ?? Date()
                    minEnd = timerVM.startTime ?? Date()
                    editedActivity = timerVM.activityLabel.isEmpty ? "Work" : timerVM.activityLabel
                    editedSubtitle = timerVM.subtitleLabel
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
                    UIAccessibility.post(notification: .announcement, argument: "Saved")
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
                    editedSubtitle = last.description ?? ""
                    editedMemo = last.memo ?? ""
                } else {
                    editedEnd = timerVM.endTime ?? Date()
                    minEnd = timerVM.startTime ?? Date()
                    editedActivity = timerVM.activityLabel.isEmpty ? "Work" : timerVM.activityLabel
                    editedSubtitle = timerVM.subtitleLabel
                    editedMemo = ""
                }
                UIAccessibility.post(notification: .announcement, argument: "Reset to original")
            }
        }
    }

    // section関数は削除（TimerEditSectionBuilderを使用）
}

// MARK: - Change detection
private extension TimerEditView {
    var isNoChanges: Bool {
        // 比較元も履歴の最後のレコードを参照（なければVMの値でフォールバック）
        let originalActivity = historyVM.history.last?.sessionName
            ?? (timerVM.activityLabel.isEmpty ? "Work" : timerVM.activityLabel)
        let originalSubtitle = historyVM.history.last?.description
            ?? timerVM.subtitleLabel
        let originalMemo = historyVM.history.last?.memo ?? ""
        let originalEnd = historyVM.history.last?.end ?? (timerVM.endTime ?? Date())
        let activitySame = editedActivity.trimmingCharacters(in: .whitespacesAndNewlines) == originalActivity
        let subtitleSame = editedSubtitle.trimmingCharacters(in: .whitespacesAndNewlines) == originalSubtitle
        // 分解能は分単位で比較（秒の僅差での誤判定を避ける）
        let cal = Calendar.current
        let comps1 = cal.dateComponents([.hour, .minute], from: editedEnd)
        let comps2 = cal.dateComponents([.hour, .minute], from: originalEnd)
        let endSame = comps1.hour == comps2.hour && comps1.minute == comps2.minute
        let memoSame = editedMemo.trimmingCharacters(in: .whitespacesAndNewlines)
            == originalMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        return activitySame && subtitleSame && endSame && memoSame
    }
}

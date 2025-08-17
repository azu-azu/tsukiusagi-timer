import SwiftUI

struct TimerEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var sessionManager: SessionManager

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

    private var isCustomActivity: Bool {
        let predefinedActivities = ["Work", "Study", "Read"]
        return !predefinedActivities.contains { $0.lowercased() == editedActivity.lowercased() }
    }

    // バリデーション関数の共通化
    private func isActivityEmpty() -> Bool {
        return editedActivity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableSave() -> Bool {
        return isCustomActivity && isActivityEmpty()
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
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 40) {
                            // Session Label
                            section(title: "Session Label") {
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
                            section(title: "Final Time") {
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

                            // Memo
                            section(title: "Memo") {
                                ZStack(alignment: .topLeading) {
                                    if editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text("Memo (optional)")
                                            .font(DesignTokens.Fonts.label)
                                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 12)
                                    }

                                    // 背景レイヤにタップ検知を置いてフォーカスを確実に付与
                                    DesignTokens.WhiteColors.surface
                                        .contentShape(Rectangle())
                                        .onTapGesture { isMemoFocused = true }

                                    TextEditor(text: $editedMemo)
                                        .frame(minHeight: 120, maxHeight: UIScreen.main.bounds.height * 0.4)
                                        .padding(8)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear) // 背景は上のレイヤーに委譲
                                        .focused($isMemoFocused)
                                }

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
                            Color.clear.frame(height: isKeyboardVisible ? keyboardBottomInset : 0)
                        }
                        // 発火タイミングは bottom inset 更新に寄せる（多重発火を抑制）
                        .onChange(of: keyboardBottomInset) { _, _ in
                            guard isKeyboardVisible, isMemoFocused, !isAutoScrolling else { return }
                            isAutoScrolling = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.easeOut(duration: 0.22)) {
                                    proxy.scrollTo(SectionID.memoAnchor, anchor: .bottom)
                                }
                                // スロットル
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                    isAutoScrolling = false
                                }
                            }
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
                    editedActivity = last.activity
                    editedSubtitle = last.subtitle ?? ""
                    editedMemo = last.memo ?? ""
                } else {
                    // フォールバック（念のため）
                    editedEnd = timerVM.endTime ?? Date()
                    minEnd = timerVM.startTime ?? Date()
                    editedActivity = timerVM.currentActivityLabel.isEmpty ? "Work" : timerVM.currentActivityLabel
                    editedSubtitle = timerVM.currentSubtitleLabel
                    editedMemo = ""
                }
            }
            // 保存系のアクションはヘッダー内のボタンで行われる想定
            // 保存成功時のフィードバックと閉じ処理を注入
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TimerEditSaved"))) { _ in
                HapticManager.shared.buttonTapFeedback()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
                // アクセシビリティ通知（保存完了）
                UIAccessibility.post(notification: .announcement, argument: "Saved")
                // 軽量トースト（HUD）は別途共通実装があればそちらを使用
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        showDone: Bool = false,
        doneAction: (() -> Void)? = nil,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 10) {
            HStack {
                Text(title)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .padding(.horizontal, 4)
                Spacer()
                if showDone, let action = doneAction {
                    Button("Done") {
                        action()
                    }
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignTokens.WhiteColors.stroke)
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showDone)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(
                isCompact
                ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                : EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            )
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(DesignTokens.CosmosColors.cardBackground)
            )
        }
    }
}

// MARK: - Change detection
private extension TimerEditView {
    var isNoChanges: Bool {
        // 比較元も履歴の最後のレコードを参照（なければVMの値でフォールバック）
        let originalActivity = historyVM.history.last?.activity
            ?? (timerVM.currentActivityLabel.isEmpty ? "Work" : timerVM.currentActivityLabel)
        let originalSubtitle = historyVM.history.last?.subtitle
            ?? timerVM.currentSubtitleLabel
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

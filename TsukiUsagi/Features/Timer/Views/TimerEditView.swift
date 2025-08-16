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

    @FocusState private var isSubtitleFocused: Bool
    @FocusState private var isMemoFocused: Bool
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
                Color.cosmosBackground.ignoresSafeArea()

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
                    .background(Color.cosmosBackground)
                    .zIndex(1)

                    // スクロール可能なコンテンツ
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

                                    TextEditor(text: $editedMemo)
                                        .frame(minHeight: 120, maxHeight: UIScreen.main.bounds.height * 0.4)
                                        .padding(8)
                                        .scrollContentBackground(.hidden)
                                        .background(DesignTokens.WhiteColors.surface)
                                        .focused($isMemoFocused)
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden) // スクロールインジケーター非表示
                    .scrollDismissesKeyboard(.interactively) // キーボード制御を改善
                    .scrollBounceBehavior(.basedOnSize) // バウンス動作を制御
                }
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.top, topPadding)
                .presentationDetents([.large])
            }
            .navigationBarHidden(true) // NavigationBarを非表示
            .modifier(DismissKeyboardOnTap(
                isActivityFocused: $isActivityFocused,
                isSubtitleFocused: $isSubtitleFocused,
                isMemoFocused: $isMemoFocused,
                isKeyboardVisible: $isKeyboardVisible
            ))
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isKeyboardVisible = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isKeyboardVisible = false
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
                // 編集画面を開いた時、現在のセッションの値をセット
                editedEnd = timerVM.endTime ?? Date()
                minEnd = timerVM.startTime ?? Date()
                editedActivity = timerVM.currentActivityLabel.isEmpty ? "Work" : timerVM.currentActivityLabel
                editedSubtitle = timerVM.currentSubtitleLabel
                editedMemo = ""
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
        let originalActivity = timerVM.currentActivityLabel.isEmpty ? "Work" : timerVM.currentActivityLabel
        let originalSubtitle = timerVM.currentSubtitleLabel
        let originalEnd = timerVM.endTime ?? Date()
        let activitySame = editedActivity.trimmingCharacters(in: .whitespacesAndNewlines) == originalActivity
        let subtitleSame = editedSubtitle.trimmingCharacters(in: .whitespacesAndNewlines) == originalSubtitle
        // 分解能は分単位で比較（秒の僅差での誤判定を避ける）
        let cal = Calendar.current
        let comps1 = cal.dateComponents([.hour, .minute], from: editedEnd)
        let comps2 = cal.dateComponents([.hour, .minute], from: originalEnd)
        let endSame = comps1.hour == comps2.hour && comps1.minute == comps2.minute
        return activitySame && subtitleSame && endSame && editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

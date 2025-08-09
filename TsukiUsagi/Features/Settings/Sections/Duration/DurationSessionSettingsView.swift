import SwiftUI

struct DurationSessionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    // Session Label 用の状態（ローカル変数として管理）
    @State private var activityLabel: String = ""
    @State private var subtitleLabel: String = ""
    @FocusState private var isActivityFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @State private var currentShowEmptyError: Bool = false

    // 保存完了メッセージ用の状態
    @State private var showSavedMessage: Bool = false

    // 元の値を保持（破棄時に復元用）
    @State private var originalActivityLabel: String = ""
    @State private var originalSubtitleLabel: String = ""

    // Session Names管理の展開状態
    @State private var isSessionNamesExpanded: Bool = false

    // レイアウト定数
    private let labelCornerRadius: CGFloat = 8
    private let betweenCardSpace: CGFloat = 24

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: betweenCardSpace) {
                            // Session Label セクション
                            section("SESSION LABEL", bottomPadding: betweenCardSpace) {
                                sessionLabelContent()
                            }

                            // Session Name Manager セクション
                            sessionNamesManagementSection()

                            Spacer(minLength: 50)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .background(DesignTokens.CosmosColors.background)

                    // 保存完了メッセージ
                    if showSavedMessage {
                        VStack {
                            Text("Saved...")
                                .font(DesignTokens.Fonts.label)
                                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DesignTokens.MoonColors.surfaceSecondary.opacity(0.9))
                                )
                        }
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1000)
                    }
                }
            }
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.navigationStack)
            .navigationBackButton {
                saveChanges()
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    // MARK: - Section Builder Helper

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        bottomPadding: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            content()
        }
        .padding(.bottom, bottomPadding)
    }

    // MARK: - Session Label Content

    @ViewBuilder
    private func sessionLabelContent() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SessionLabelSection(
                activity: $activityLabel,
                descriptionText: $subtitleLabel,
                isActivityFocused: $isActivityFocused,
                isDescriptionFocused: $isSubtitleFocused,
                labelCornerRadius: labelCornerRadius,
                showEmptyError: $currentShowEmptyError,
                onDone: {
                    // フォーカスを外す
                    isActivityFocused = false
                    isSubtitleFocused = false
                }
            )
        }
        .padding(.all)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
    }

    // MARK: - Session Names Management Section

    @ViewBuilder
    private func sessionNamesManagementSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sessionNamesToggleButton()
            sessionNamesExpandedContent()
        }
    }

    @ViewBuilder
    private func sessionNamesToggleButton() -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                isSessionNamesExpanded.toggle()
            }
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: isSessionNamesExpanded ? "chevron.down" : "chevron.right")
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(DesignTokens.MoonColors.textMuted)
                        Text("Manage session names")
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    }
                    if !isSessionNamesExpanded {
                        sessionNamesPreview()
                            .padding(.leading, 18)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.CosmosColors.cardBackground)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func sessionNamesExpandedContent() -> some View {
        if isSessionNamesExpanded {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                    .background(DesignTokens.MoonColors.surfaceSecondary)

                EmbeddedSessionManagementView()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.CosmosColors.cardBackground)
            )
            .transition(.opacity.combined(with: .scale(scale: 1.0, anchor: .top)))
        }
    }

    // MARK: - Session Names Preview

    @ViewBuilder
    private func sessionNamesPreview() -> some View {
        let sessionNames = sessionManager.allEntries.map { $0.sessionName }
        let previewText = createPreviewText(from: sessionNames)
        if !previewText.isEmpty {
            Text(previewText)
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private func createPreviewText(from sessionNames: [String]) -> String {
        if sessionNames.isEmpty {
            return "No sessions yet"
        }
        // 最初の3つまでを表示
        let displayNames = Array(sessionNames.prefix(3))
        let previewText = displayNames.joined(separator: ", ")
        // 3つ以上ある場合は "..." を追加
        if sessionNames.count > 3 {
            return previewText + "..."
        } else {
            return previewText
        }
    }

    // MARK: - Helper Methods

    private func loadCurrentValues() {
        // UserDefaultsから現在の値を読み込み
        let currentActivity = UserDefaults.standard.string(forKey: "activityLabel") ?? "Work"
        let currentSubtitle = UserDefaults.standard.string(forKey: "subtitleLabel") ?? ""

        activityLabel = currentActivity
        subtitleLabel = currentSubtitle
        originalActivityLabel = currentActivity
        originalSubtitleLabel = currentSubtitle
    }

    private func saveChanges() {
        // 変更があったかチェック
        let hasChanges = activityLabel != originalActivityLabel || subtitleLabel != originalSubtitleLabel

        if hasChanges {
            // UserDefaultsに保存
            UserDefaults.standard.set(activityLabel, forKey: "activityLabel")
            UserDefaults.standard.set(subtitleLabel, forKey: "subtitleLabel")

            // タイマーシステムに反映
            timerVM.refreshAfterSettingsChange()

            // 保存完了メッセージを表示
            withAnimation(.easeInOut(duration: 0.3)) {
                showSavedMessage = true
            }

            // 1秒後にメッセージを非表示にして画面を閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSavedMessage = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // サイドメニューを開くリクエストを送る
                    sessionManager.requestSideMenuOnDismiss()
                    dismiss()
                }
            }
        } else {
            // 変更がない場合は即座に画面を閉じる
            sessionManager.requestSideMenuOnDismiss()
            dismiss()
        }
    }

    private func discardChanges() {
        // 元の値に戻す（破棄）
        activityLabel = originalActivityLabel
        subtitleLabel = originalSubtitleLabel

        // サイドメニューを開くリクエストを送る
        sessionManager.requestSideMenuOnDismiss()
        dismiss()
    }
}

#if DEBUG
struct DurationSessionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // プレビューを簡素化してビルドエラーを回避
        Text("Duration & Session Settings View")
            .padding()
    }
}
#endif

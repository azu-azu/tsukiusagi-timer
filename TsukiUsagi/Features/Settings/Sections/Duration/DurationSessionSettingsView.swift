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

    // レイアウト定数
    private let labelCornerRadius: CGFloat = 8
    private let betweenCardSpace: CGFloat = 24

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: betweenCardSpace) {
                            // Duration セクション
                            section("DURATION", bottomPadding: betweenCardSpace) {
                                DurationSectionView()
                            }

                            // Session Label セクション
                            section("SESSION LABEL", bottomPadding: betweenCardSpace) {
                                sessionLabelContent()
                            }

                            // Session Name Manager セクション
                            section("MANAGE SESSION NAMES", bottomPadding: betweenCardSpace) {
                                NavigationLink(destination: SessionNameManagerView()
                                    .environmentObject(sessionManager)
                                ) {
                                    HStack {
                                        Text("Manage session names")
                                            .font(DesignTokens.Fonts.label)
                                            .foregroundColor(DesignTokens.MoonColors.textPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(DesignTokens.Fonts.caption)
                                            .foregroundColor(DesignTokens.MoonColors.textMuted)
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
            .navigationTitle("Duration & Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.navigationStack)
            .navigationBackButton {
                saveChanges()
            }
        }
        .environmentObject(sessionManager)
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
        .environmentObject(sessionManager)
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

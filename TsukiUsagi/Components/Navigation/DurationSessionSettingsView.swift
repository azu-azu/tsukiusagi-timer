import SwiftUI

struct DurationSessionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    // Session Label 用の状態
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") private var subtitleLabel: String = ""
    @FocusState private var isActivityFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @State private var currentShowEmptyError: Bool = false

    // レイアウト定数
    private let labelCornerRadius: CGFloat = 8
    private let betweenCardSpace: CGFloat = 24

    var body: some View {
        NavigationView {
            GeometryReader { _ in

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

                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .background(DesignTokens.CosmosColors.background)
            }
            .navigationTitle("Duration & Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
            }
        }
        .environmentObject(sessionManager)
    }

    // MARK: - Section Builder Helper

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        bottomPadding: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .environmentObject(sessionManager)
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

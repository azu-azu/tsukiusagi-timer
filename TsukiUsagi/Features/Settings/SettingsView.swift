import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var sessionManagerV2: SessionManagerV2
    @Environment(\.horizontalSizeClass) private var horizontalClass
    @Environment(\.verticalSizeClass) private var verticalClass

    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("subtitleLabel") private var subtitleLabel: String = ""

    @FocusState private var isActivityFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @FocusState private var dummyMemoFocused: Bool



    // workMinutesの選択肢: 1, 3, 5, 10, 15, ... 60
    private let workMinutesOptions: [Int] = [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))

    // ヘッダー周りのpadding
    private let headerTopPadding: CGFloat = 5
    private let headerBottomPadding: CGFloat = 34

    // plusMinusボタン
    private let plusMinusSize: CGFloat = 12
    private let plusMinusPadding: CGFloat = 10

    private let betweenCardSpaceNarrow: CGFloat = 4
    private let betweenCardSpace: CGFloat = 24
    private let breakBottomPadding: CGFloat = 26

    private let timeTitleWidth: CGFloat = 80 // WORK, BREAK の文字の幅

    private let cardCornerRadius: CGFloat = 8
    private let labelCornerRadius: CGFloat = 6
    private let clipRadius: CGFloat = 30 // 画面全体のコーナー

    // 星の数
    private let flowingStarCount: Int = 20

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    private var isCustomActivity: Bool {
        !["Work", "Study", "Read"].contains(activityLabel)
    }

    // バリデーション関数の共通化
    private func isActivityEmpty() -> Bool {
        return activityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableDone() -> Bool {
        return isCustomActivity && isActivityEmpty()
    }

    // リアルタイムでエラー状態を計算
    private var currentShowEmptyError: Bool {
        return isCustomActivity && isActivityEmpty()
    }

    // プラスマイナスボタンの共通化（新しいコンポーネントを使用）
    @ViewBuilder
    private func plusMinusButtons(
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        PlusMinusButtonPair(
            onMinus: onMinus,
            onPlus: onPlus,
            spacing: DesignTokens.Spacing.small
        )
    }

    // 🕐 時間設定セクションの共通化
    @ViewBuilder
    private func timeSettingSection(
        title: String,
        minutes: Int,
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void,
        bottomPadding: CGFloat
    ) -> some View {
        section(title: "", isCompact: true) {
            HStack {
                Text(title)
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                    .frame(width: timeTitleWidth, alignment: .leading)

                Text(String(format: "%2d min", minutes))
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)

                Spacer()

                plusMinusButtons(onMinus: onMinus, onPlus: onPlus)
            }
        }
        .padding(.bottom, bottomPadding)
    }

    // body
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 自作ヘッダー
                        HStack {
                            Button("Close") {
                                dismiss()
                            }
                            .foregroundColor(DesignTokens.Colors.moonTextSecondary)

                            Spacer()

                            Button("Done") {
                                dismiss()
                            }
                            .disabled(shouldDisableDone())
                            .foregroundColor(
                                shouldDisableDone()
                                    ? .gray
                                    : DesignTokens.Colors.moonAccentBlue
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, headerTopPadding)
                        .padding(.bottom, headerBottomPadding)

                        workTimeSection()
                            .padding(.bottom, betweenCardSpaceNarrow)

                        breakTimeSection()
                            .padding(.bottom, breakBottomPadding)

                        sessionLabelSection()
                            .padding(.bottom, betweenCardSpaceNarrow)

                        manageSessionNamesSection()
                            .padding(.bottom, betweenCardSpace)

                        resetStopSection()
                            .padding(.bottom, betweenCardSpace)

                        viewHistorySection()
                            .padding(.bottom, betweenCardSpace)
                    }
                    .padding()
                }
                .background(
                    ZStack {
                        Color.moonBackground.ignoresSafeArea()
                        StaticStarsView(starCount: 30).allowsHitTesting(false)
                        FlowingStarsView(
                            starCount: flowingStarCount,
                            angle: .degrees(135),
                            durationRange: 24 ... 40,
                            sizeRange: 2 ... 4,
                            spawnArea: nil
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: clipRadius))
                .padding(.top, 0)
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: isCompact
                ? DesignTokens.Spacing.extraSmall
                : DesignTokens.Spacing.small
        ) {
            if !title.isEmpty {
                Text(title)
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(isCompact
                ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                : EdgeInsets())
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(DesignTokens.Colors.moonCardBG)
            )
        }
    }

    private func workTimeSection() -> some View {
        section(title: "", isCompact: true) {
            HStack {
                Text("WORK")
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                    .frame(width: timeTitleWidth, alignment: .leading)
                Text(String(format: "%2d min", workMinutes))
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                Spacer()
                plusMinusButtons(
                    onMinus: {
                        let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                        if currentIndex > 0 {
                            workMinutes = workMinutesOptions[currentIndex - 1]
                        }
                    },
                    onPlus: {
                        let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                        if currentIndex < workMinutesOptions.count - 1 {
                            workMinutes = workMinutesOptions[currentIndex + 1]
                        }
                    }
                )
            }
        }
    }

    private func breakTimeSection() -> some View {
        section(title: "", isCompact: true) {
            HStack {
                Text("BREAK")
                    .font(DesignTokens.Fonts.labelBold)
                    .foregroundColor(DesignTokens.Colors.moonTextSecondary)
                    .frame(width: timeTitleWidth, alignment: .leading)
                Text(String(format: "%2d min", breakMinutes))
                    .font(DesignTokens.Fonts.numericLabel)
                    .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                Spacer()
                plusMinusButtons(
                    onMinus: { if breakMinutes > 1 { breakMinutes -= 1 } },
                    onPlus: { if breakMinutes < 30 { breakMinutes += 1 } }
                )
            }
        }
    }

    private func sessionLabelSection() -> some View {
        section(title: "Session Label") {
            SessionLabelSection(
                activity: $activityLabel,
                subtitle: $subtitleLabel,
                isActivityFocused: $isActivityFocused,
                isSubtitleFocused: $isSubtitleFocused,
                labelCornerRadius: labelCornerRadius,
                showEmptyError: .constant(currentShowEmptyError),
                onDone: nil
            )
        }
    }

    private func manageSessionNamesSection() -> some View {
        section(title: "", isCompact: true) {
            NavigationLink(
                destination: SessionNameManagerView().environmentObject(sessionManagerV2)
            ) {
                HStack {
                    Text("Manage Session Names")
                        .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignTokens.Colors.moonTextMuted)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func resetStopSection() -> some View {
        section(title: "", isCompact: false) {
            VStack(spacing: 14) {
                Button {
                    timerVM.resetTimer()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        // 🛑 Reset
                        Image(systemName: "arrow.uturn.backward")
                        Text(timerVM.isWorkSession
                            ? "Reset Timer (No Save)"
                            : "Reset Timer (already saved)"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .tint(.red.opacity(0.8))

                // 🛑 Stop
                if timerVM.isWorkSession && timerVM.startTime != nil {
                    Button {
                        Task {
                            await timerVM.forceFinishWorkSession()
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.end")
                            Text("Stop (Save)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(.blue)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.end")
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Stop (Save)")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func viewHistorySection() -> some View {
        section(title: "", isCompact: true) {
            NavigationLink(destination: HistoryView().environmentObject(historyVM)) {
                HStack {
                    Text("View History")
                        .foregroundColor(DesignTokens.Colors.moonTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignTokens.Colors.moonTextMuted)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    var isActivityFocused: FocusState<Bool>.Binding
    var isSubtitleFocused: FocusState<Bool>.Binding
    var isMemoFocused: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        content.onTapGesture {
            UIApplication.shared.endEditing()
            isActivityFocused.wrappedValue = false
            isSubtitleFocused.wrappedValue = false
            isMemoFocused.wrappedValue = false
        }
    }
}

// 横画面判定用ユーティリティ
private func safeIsLandscape(size: CGSize, horizontalClass: UserInterfaceSizeClass?, verticalClass _: UserInterfaceSizeClass?) -> Bool {
    // ルール集推奨の判定
    return horizontalClass == .regular || size.width > size.height
}

#if DEBUG
    struct SettingsView_Previews: PreviewProvider {
        static var previews: some View {
            SettingsView(size: .init(width: 375, height: 812), safeAreaInsets: .init())
                .environmentObject(TimerViewModel(historyVM: HistoryViewModel()))
                .environmentObject(HistoryViewModel())
                .environmentObject(SessionManager())
                .environmentObject(SessionManagerV2())
        }
    }
#endif

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    @AppStorage("workMinutes") private var workMinutes: Int = 25
    @AppStorage("breakMinutes") private var breakMinutes: Int = 5
    @AppStorage("activityLabel") private var activityLabel: String = "Work"
    @AppStorage("detailLabel") private var detailLabel: String = ""

    @FocusState private var isActivityFocused: Bool
    @FocusState private var isDetailFocused: Bool

    // TODO: 将来的に中間バッファを導入する可能性を考慮
    // 現在は直接AppStorageにBindingしているが、
    // 複雑なバリデーションや一時保存が必要になった場合は
    // @State private var tempActivityLabel を導入することを検討

    private let workMinutesOptions: [Int] =
        [1, 3, 5] + Array(stride(from: 10, through: 60, by: 5))

    // ヘッダー周りのpadding
    private let headerTopPadding: CGFloat = 20
    private let headerBottomPadding: CGFloat = 24

    // plusMinusボタン
    private let plusMinusSize: CGFloat = 12
    private let plusMinusPadding: CGFloat = 10

    private let betweenCardSpaceNarrow: CGFloat = 4
    private let betweenCardSpace: CGFloat = 24
    private let breakBottomPadding: CGFloat = 26

    private let labelHeight: CGFloat = 28
    private let inputHeight: CGFloat = 42
    private let timeTitleWidth: CGFloat = 80 // WORK, BREAK の文字の幅

    private let cardCornerRadius: CGFloat = 8
    private let labelCornerRadius: CGFloat = 6
    private let clipRadius: CGFloat = 30 // 画面全体のコーナー

    // 星の数
    private let flowingStarCount: Int = 40

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

    // プラスマイナスボタンの共通化
    @ViewBuilder
    private func plusMinusButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: plusMinusSize, height: plusMinusSize)
                .foregroundColor(.white)
                .padding(plusMinusPadding)
                .background(Circle().fill(Color.white.opacity(0.1)))
        }
    }

    @ViewBuilder
    private func plusMinusButtons(
        onMinus: @escaping () -> Void,
        onPlus: @escaping () -> Void
    ) -> some View {
        HStack() {
            plusMinusButton(systemName: "minus", action: onMinus)
            plusMinusButton(systemName: "plus", action: onPlus)
        }
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
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.moonTextSecondary)
                    .frame(width: timeTitleWidth, alignment: .leading)

                Text(String(format: "%2d min", minutes))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.moonTextPrimary)

                Spacer()

                plusMinusButtons(onMinus: onMinus, onPlus: onPlus)
            }
        }
        .padding(.bottom, bottomPadding)
    }

    // body
    var body: some View {
        guard size.width > 0 && size.height > 0 else {
            return AnyView(EmptyView())
        }

        return AnyView(
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // ヘッダー
                        HStack {
                            Button("Close") {
                                dismiss()
                            }
                            .foregroundColor(.moonTextSecondary)

                            Spacer()

                            Button("Done") {
                                dismiss()
                            }
                            .disabled(shouldDisableDone())
                            .foregroundColor(shouldDisableDone() ? .gray : .moonAccentBlue)
                        }

                        // ヘッダー周りのpadding
                        .padding(.horizontal)
                        .padding(.top, headerTopPadding)
                        .padding(.bottom, headerBottomPadding)

                        // 🕐 Work Length
                        timeSettingSection(title: "WORK", minutes: workMinutes, onMinus: {
                            let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                            if currentIndex > 0 {
                                workMinutes = workMinutesOptions[currentIndex - 1]
                            }
                        }, onPlus: {
                            let currentIndex = workMinutesOptions.firstIndex(of: workMinutes) ?? 0
                            if currentIndex < workMinutesOptions.count - 1 {
                                workMinutes = workMinutesOptions[currentIndex + 1]
                            }
                        }, bottomPadding: betweenCardSpaceNarrow)

                        // 🕐 Break Length
                        timeSettingSection(title: "BREAK", minutes: breakMinutes, onMinus: {
                            if breakMinutes > 1 {
                                breakMinutes -= 1
                            }
                        }, onPlus: {
                            if breakMinutes < 30 {
                                breakMinutes += 1
                            }
                        }, bottomPadding: breakBottomPadding)

                        // Session Label
                        section(title: "Session Label") {
                            SessionLabelSection(
                                activity: $activityLabel,
                                detail: $detailLabel,
                                isActivityFocused: $isActivityFocused,
                                isDetailFocused: $isDetailFocused,
                                labelHeight: labelHeight,
                                labelCornerRadius: labelCornerRadius,
                                inputHeight: inputHeight,
                                showEmptyError: .constant(currentShowEmptyError),
                                onDone: nil
                            )
                        }
                        // Session Label周りのpadding
                        .padding(.bottom, betweenCardSpaceNarrow)

                        // Manage Session Names
                        section(title: "", isCompact: true) {
                            NavigationLink(destination: SessionNameManagerView().environmentObject(sessionManager)) {
                                HStack {
                                    Text("Manage Session Names")
                                        .foregroundColor(.moonTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.moonTextMuted)
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        // Manage Session Names周りのpadding
                        .padding(.bottom, betweenCardSpace)

                        // Session Control
                        section(title: "", isCompact: false) {
                            VStack(spacing: 14) {
                                Button() {
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
                                        timerVM.forceFinishWorkSession()
                                        dismiss()
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

                        // Session Control周りのpadding
                        .padding(.bottom, betweenCardSpace)

                        // Logs
                        section(title: "", isCompact: true) {
                            NavigationLink(destination: HistoryView().environmentObject(historyVM)) {
                                HStack {
                                    Text("View History")
                                        .foregroundColor(.moonTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.moonTextMuted)
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        Spacer(minLength: 40)
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
                            durationRange: 24...40,
                            sizeRange: 2...4,
                            spawnArea: nil
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: clipRadius))
                .padding(.top, 0) // デフォルト背景と宇宙背景との間 ※余白をつけるとデフォルト背景（白または黒）が見える
                .presentationDetents([.large])
                .modifier(DismissKeyboardOnTap(
                    isActivityFocused: $isActivityFocused,
                    isDetailFocused: $isDetailFocused,
                    isMemoFocused: nil
                ))
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Close") {
                        isActivityFocused = false
                        isDetailFocused = false
                    }
                }
            }
        )
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        isCompact: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 10) {
        // VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.moonTextSecondary)
                    // .padding(.horizontal, 2)
            }

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(isCompact ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12) : EdgeInsets())
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(Color.moonCardBackground.opacity(0.15))
            )
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
    var isDetailFocused: FocusState<Bool>.Binding
    var isMemoFocused: FocusState<Bool>.Binding?

    func body(content: Content) -> some View {
        content.onTapGesture {
            UIApplication.shared.endEditing()
            isActivityFocused.wrappedValue = false
            isDetailFocused.wrappedValue = false
            isMemoFocused?.wrappedValue = false
        }
    }
}

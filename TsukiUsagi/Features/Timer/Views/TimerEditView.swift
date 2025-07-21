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
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    // ヘッダー
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.moonTextSecondary)

                        Spacer()

                        Text("Edit Record")
                            .font(DesignTokens.Fonts.labelBold)
                            .foregroundColor(.moonTextPrimary)

                        Spacer()

                        Button("Save") {
                            historyVM.updateLast(activity: editedActivity,
                                                subtitle: editedSubtitle,
                                                memo: editedMemo,
                                                end: editedEnd)
                            timerVM.setEndTime(editedEnd)
                            dismiss()
                        }
                        .foregroundColor(shouldDisableSave() ? .gray : .moonAccentBlue)
                        .disabled(shouldDisableSave())
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Session Label
                    section(title: "Session Label") {
                        SessionLabelSection(
                            activity: $editedActivity,
                            subtitle: $editedSubtitle,
                            isActivityFocused: $isActivityFocused,
                            isSubtitleFocused: $isSubtitleFocused,
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
                        .foregroundColor(.moonTextPrimary)
                        .colorScheme(.dark)
                    }

                    // Memo
                    section(title: "Memo") {
                        ZStack(alignment: .topLeading) {
                            if editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Memo (optional)")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }

                            TextEditor(text: $editedMemo)
                                .frame(minHeight: 120, maxHeight: UIScreen.main.bounds.height * 0.4)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.05))
                                .focused($isMemoFocused)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .scrollIndicators(.hidden) // スクロールインジケーター非表示
            .scrollDismissesKeyboard(.interactively) // キーボード制御を改善
            .padding(.bottom, 20) // Safe Area対応
            .background(
                ZStack {
                    Color.moonBackground.ignoresSafeArea()

                    // キーボード表示時は星を非表示
                    // if !isKeyboardVisible {
                    //     StaticStarsView(starCount: 40)
                    //         .allowsHitTesting(false)
                    //         .transition(.opacity.animation(.easeInOut(duration: 0.3)))

                    //     FlowingStarsView(
                    //         starCount: 40,
                    //         angle: .degrees(135),
                    //         durationRange: 24 ... 40,
                    //         sizeRange: 2 ... 4,
                    //         spawnArea: nil
                    //     )
                    //     .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    // }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .padding(.top, topPadding)
            .presentationDetents([.large])
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
                    .foregroundColor(.moonTextSecondary)
                    .padding(.horizontal, 4)
                Spacer()
                if showDone, let action = doneAction {
                    Button("Done") {
                        action()
                    }
                    .foregroundColor(.moonTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showDone)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(isCompact ? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12) : EdgeInsets())
            .padding(isCompact ? .init() : .all)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(DesignTokens.Colors.moonCardBG)
            )
        }
    }
}

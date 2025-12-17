import SwiftUI
import UIKit

struct DailyTimelineView: View {
    let targetDate: Date
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    // 新しいViewModelとBuilder（既存コードと並行動作）
    @StateObject private var viewModel: DailyTimelineViewModel
    @StateObject private var detailViewModel: HistoryDetailViewModel
    private let sectionBuilder = DailyTimelineSectionBuilder()
    private let gestureHandler = DailyTimelineGestureHandler()
    private let dataProvider = DailyTimelineDataProvider()
    @FocusState private var isReflectionFocused: Bool
    @State private var showReflectionSheet = false
    @State private var showReflectionInput = false

    // 初期化
    init(targetDate: Date) {
        self.targetDate = targetDate
        self._viewModel = StateObject(wrappedValue: DailyTimelineViewModel(targetDate: targetDate))
        self._detailViewModel = StateObject(wrappedValue: HistoryDetailViewModel(targetDate: targetDate))
    }

    var body: some View {
        VStack(spacing: 0) {
            TotalCard(text: TimeFormatters.totalTextWithSeconds(
                dataProvider.totalSeconds(historyVM: historyVM, targetDate: targetDate)
            ))
            .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 16) {
                    let sessionSummaries = dataProvider
                        .daySessionSummaries(historyVM: historyVM, targetDate: targetDate)
                    if !sessionSummaries.isEmpty {
                        DailyTimelineSummaryTreeView(
                            sessions: sessionSummaries,
                            displayName: { sessionName in
                                historyVM.displaySessionName(
                                    sessionManager: sessionManager,
                                    sessionName: sessionName
                                )
                            }
                        )
                    }

                    // Reflection section with placeholder card
                    DailyTimelineReflectionCard(
                        text: detailViewModel.reflectionText,
                        isSaving: detailViewModel.isSaving,
                        error: detailViewModel.error,
                        isEditing: showReflectionInput,
                        onRetry: { detailViewModel.retry() },
                        onTap: {
                            showReflectionInput = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isReflectionFocused = true
                            }
                        }
                    )

                    sectionBuilder.dayModeRecordsSection(
                        records: viewModel.records(historyVM: historyVM),
                        onRestore: { record in
                            viewModel.restoreRecord(record, historyVM: historyVM, sessionManager: sessionManager)
                        }
                    )
                }
                .padding(.horizontal)
            }
            .scrollDismissesKeyboard(.interactively)
            // コンテンツ領域のタップでキーボードだけを閉じる（入力バーは残す）
            .contentShape(Rectangle())
            .onTapGesture {
                guard showReflectionInput else { return }
                // キーボードだけ閉じる（入力バーは残る）
                isReflectionFocused = false
                Keyboard.dismiss()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showReflectionInput {
                BottomInputBar(
                    text: $detailViewModel.reflectionText,
                    isFocused: $isReflectionFocused,
                    placeholder: LocalizedStringKey("reflection_placeholder"),
                    onExpand: {
                        // BottomInputBarが内部でtextを更新してからここに来る
                        isReflectionFocused = false
                        showReflectionInput = false
                        showReflectionSheet = true
                    },
                    onSubmit: {
                        // BottomInputBarが内部でtextを更新してからここに来る
                        isReflectionFocused = false
                        showReflectionInput = false
                        Keyboard.dismiss()
                    }
                )
            }
        }
        .simultaneousGesture(gestureHandler.backSwipeGesture())
        .navigationTitle(targetDate.formatted(.dateTime.weekday(.wide).month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.showRestoreAlert) {
            Alert(
                title: Text("Restore Error"),
                message: Text(viewModel.restoreError ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(DesignTokens.SkyToneColors.backgroundGradient.ignoresSafeArea())
        .modifier(DailyTimelineKeyboardAwareInset(isEnabled: false))
        .sheet(isPresented: $showReflectionSheet) {
            LargeTextEditorSheet(
                text: $detailViewModel.reflectionText,
                title: Labels.Sections.reflection,
                placeholder: LocalizedStringKey("reflection_placeholder"),
                onClose: { showReflectionSheet = false }
            )
        }
        .onAppear {
            detailViewModel.attach(historyViewModel: historyVM)
            // View Details画面ではbackスワイプを有効化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                enableBackSwipeGesture()
            }
        }
        .onDisappear {
            detailViewModel.flush()
            // History画面に戻る際はbackスワイプを無効化
            disableBackSwipeGesture()
        }
    }
}

// MARK: - Subviews
private struct DailyTimelineSummaryTreeView: View {
    let sessions: [DaySessionSummary]
    let displayName: (String) -> String
    private let maxTasksPerSession = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sessions, id: \.self) { session in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(displayName(session.sessionName))
                            .font(DesignTokens.Fonts.labelBold)
                            .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 12)
                        Text(formattedDuration(session.total))
                            .font(DesignTokens.Fonts.labelBold)
                            .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                            .monospacedDigit()
                    }

                    if !session.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(
                                Array(session.tasks.prefix(maxTasksPerSession)),
                                id: \.title
                            ) { slice in
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text(slice.title.withTaskEmoji)
                                        .font(DesignTokens.Fonts.label)
                                        .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                                        .lineLimit(1)
                                        .padding(.leading, 12)
                                    Spacer(minLength: 12)
                                    Text(formattedDuration(slice.duration))
                                        .font(DesignTokens.Fonts.caption)
                                        .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                                        .monospacedDigit()
                                }
                            }

                            let extraCount = session.tasks.count - maxTasksPerSession
                            if extraCount > 0 {
                                Text("history_summary_more_tasks \(extraCount)")
                                    .font(DesignTokens.Fonts.caption)
                                    .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tsukiSoundCard()
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        TimeFormatters.totalTextWithSeconds(Int(interval.rounded()))
    }
}

/// Reflection section with placeholder card (no outer card wrapper)
private struct DailyTimelineReflectionCard: View {
    let text: String
    let isSaving: Bool
    let error: Error?
    let isEditing: Bool
    let onRetry: () -> Void
    let onTap: () -> Void

    private let placeholderTextKey: LocalizedStringKey = "reflection_placeholder"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Labels.Sections.reflection)
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

            // Tappable placeholder card (full width, no outer card wrapper)
            EditablePlaceholderCard(
                text: text,
                placeholder: placeholderTextKey,
                isEditing: isEditing,
                onTap: onTap
            )

            if isSaving {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("history_inline_reflection_saving")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                }
            }

            if let error {
                VStack(alignment: .leading, spacing: 8) {
                    Text("history_inline_reflection_error_message")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                    Text(error.localizedDescription)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                    Button(action: onRetry) {
                        Text(Copy.Button.retry)
                            .font(DesignTokens.Fonts.labelBold)
                            .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .accessibilityIdentifier("banner_history_reflection_retry")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DailyTimelineKeyboardAwareInset: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.keyboardAwareInset()
        } else {
            content
        }
    }
}

private extension DailyTimelineView {
    // MARK: - Back Swipe Control
    private func disableBackSwipeGesture() {
        DispatchQueue.main.async {
            // NavigationStackのUINavigationControllerを取得してbackスワイプを無効化
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                findNavigationController(in: window.rootViewController)?
                    .interactivePopGestureRecognizer?
                    .isEnabled = false
            }
        }
    }

    private func enableBackSwipeGesture() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let navController = findNavigationController(in: window.rootViewController)
                // より安全な有効化（visual style警告を避ける）
                if let gestureRecognizer = navController?.interactivePopGestureRecognizer {
                    gestureRecognizer.isEnabled = true
                    // delegateは設定しない（警告回避）
                }
            }
        }
    }

    private func findNavigationController(in viewController: UIViewController?) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        for child in viewController?.children ?? [] {
            if let found = findNavigationController(in: child) {
                return found
            }
        }
        return nil
    }
}

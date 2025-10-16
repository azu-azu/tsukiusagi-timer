import SwiftUI
import Foundation
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

    // 既存のプロパティ（後方互換性のため保持）
    @State private var restoreError: String?
    @State private var showRestoreAlert = false
    private let cal = Calendar.current
    private let dayModeCardHeight: CGFloat = 40
    private let dayModeCardSpacing: CGFloat = 2
    private let timeWidth: CGFloat = 100
    private let summaryCardHeight: CGFloat = 50

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
                    DailyTimelineInlineReflectionSection(
                        text: $detailViewModel.reflectionText,
                        isSaving: detailViewModel.isSaving,
                        error: detailViewModel.error,
                        onRetry: { detailViewModel.retry() },
                        focus: $isReflectionFocused
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isReflectionFocused = false
                        showReflectionSheet = true
                    }

                    sectionBuilder.dayModeRecordsSection(
                        records: viewModel.records(historyVM: historyVM),
                        showsMemoButton: false,
                        onRestore: { record in
                            viewModel.restoreRecord(record, historyVM: historyVM, sessionManager: sessionManager)
                        },
                        onMemoEdit: { _ in }
                    )
                }
                .padding(.horizontal)
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    guard isReflectionFocused else { return }
                    isReflectionFocused = false
                    Task { @MainActor in
                        Keyboard.dismiss()
                    }
                }
            )
        }
        .simultaneousGesture(gestureHandler.backSwipeGesture())
        .navigationTitle(targetDate.formatted(.dateTime.weekday(.wide).month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showRestoreAlert) {
            Alert(
                title: Text("Restore Error"),
                message: Text(restoreError ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
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
                            .foregroundColor(DesignTokens.MoonColors.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 12)
                        Text(formattedDuration(session.total))
                            .font(DesignTokens.Fonts.labelBold)
                            .foregroundColor(DesignTokens.MoonColors.textSecondary)
                            .monospacedDigit()
                    }

                    if !session.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(
                                Array(session.tasks.prefix(maxTasksPerSession)),
                                id: \.title
                            ) { slice in
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text(slice.title)
                                        .font(DesignTokens.Fonts.label)
                                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                                        .lineLimit(1)
                                        .padding(.leading, 12)
                                    Spacer(minLength: 12)
                                    Text(formattedDuration(slice.duration))
                                        .font(DesignTokens.Fonts.caption)
                                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                                        .monospacedDigit()
                                }
                            }

                            let extraCount = session.tasks.count - maxTasksPerSession
                            if extraCount > 0 {
                                Text("history_summary_more_tasks \(extraCount)")
                                    .font(DesignTokens.Fonts.caption)
                                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(12)
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        TimeFormatters.totalTextWithSeconds(Int(interval.rounded()))
    }
}

private struct DailyTimelineInlineReflectionSection: View {
    @Binding var text: String
    let isSaving: Bool
    let error: Error?
    let onRetry: () -> Void
    let focus: FocusState<Bool>.Binding

    private let placeholderTextKey: LocalizedStringKey = "reflection_placeholder"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Labels.Sections.reflection)
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused(focus)
                    .frame(minHeight: 160)
                    .padding(12)
                    .background(DesignTokens.WhiteColors.surface)
                    .cornerRadius(8)
                    .textEditorStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .lineSpacing(4)
                    .accessibilityIdentifier("history_detail_reflection_editor")

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholderTextKey)
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }

            if isSaving {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("history_inline_reflection_saving")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }
            }

            if let error {
                VStack(alignment: .leading, spacing: 8) {
                    Text("history_inline_reflection_error_message")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Text(error.localizedDescription)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    Button(action: onRetry) {
                        Text(Copy.Button.retry)
                            .font(DesignTokens.Fonts.labelBold)
                            .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(8)
                .accessibilityIdentifier("banner_history_reflection_retry")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(12)
        .keyboardAwareBottomPadding(baseBottomPadding: 16)
        .keyboardCloseToolbar(
            labelStyle: .iconWithText(Copy.Button.close)
        ) {
            focus.wrappedValue = false
            Keyboard.dismiss()
        }
        .onDisappear {
            focus.wrappedValue = false
        }
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

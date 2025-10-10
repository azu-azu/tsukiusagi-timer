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

    // 既存のプロパティ（後方互換性のため保持）
    @State private var restoreError: String?
    @State private var showRestoreAlert = false
    @State private var selectedRecordForMemoEdit: SessionRecord?
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
    private var inlineReflectionEnabled: Bool { FeatureFlags.historyInlineReflection }
    private var memoSheetBinding: Binding<SessionRecord?> {
        inlineReflectionEnabled ? .constant(nil) : $selectedRecordForMemoEdit
    }
    var body: some View {
        VStack(spacing: 0) {
            TotalCard(text: TimeFormatters.totalTextWithSeconds(
                dataProvider.totalSeconds(historyVM: historyVM, targetDate: targetDate)
            ))
            .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 16) {
                    if inlineReflectionEnabled {
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
                    } else {
                        if viewModel.records(historyVM: historyVM).count > 1 {
                            sectionBuilder.activitySummarySection(summaries: viewModel.byActivity(historyVM: historyVM))
                            sectionBuilder.subtitleSummarySection(summaries: viewModel.bySubtitle(historyVM: historyVM))
                        }
                        memoSection()
                    }

                    sectionBuilder.dayModeRecordsSection(
                        records: viewModel.records(historyVM: historyVM),
                        showsMemoButton: !inlineReflectionEnabled,
                        onRestore: { record in
                            viewModel.restoreRecord(record, historyVM: historyVM, sessionManager: sessionManager)
                        },
                        onMemoEdit: { record in
                            viewModel.selectRecordForMemoEdit(record)
                        }
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
        .sheet(item: memoSheetBinding) { record in
            MemoEditView(record: record, anchorDate: targetDate)
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        .modifier(DailyTimelineKeyboardAwareInset(isEnabled: !inlineReflectionEnabled))
        .onAppear {
            if inlineReflectionEnabled {
                detailViewModel.attach(historyViewModel: historyVM)
                selectedRecordForMemoEdit = nil
            }
            // View Details画面ではbackスワイプを有効化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                enableBackSwipeGesture()
            }
        }
        .onDisappear {
            if inlineReflectionEnabled {
                detailViewModel.flush()
            }
            // History画面に戻る際はbackスワイプを無効化
            disableBackSwipeGesture()
        }
    }
}

// MARK: - Subviews
private struct DailyTimelineSummaryTreeView: View {
    let sessions: [DaySessionSummary]
    let displayName: (String) -> String
    private let maxDescriptionsPerSession = 5

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

                    if !session.descriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(
                                Array(session.descriptions.prefix(maxDescriptionsPerSession)),
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

                            if session.descriptions.count > maxDescriptionsPerSession {
                                Text("+ \(session.descriptions.count - maxDescriptionsPerSession) more")
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

    private let placeholderText = Copy.Reflection.placeholder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.Reflection.title)
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
                    Text(placeholderText)
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
                    Text("Saving…")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }
            }

            if let error {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Failed to save. Try again?")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Text(error.localizedDescription)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    Button(action: onRetry) {
                        Text("Retry")
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
        .keyboardCloseToolbar(labelStyle: .iconWithText("Close")) {
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
    // MARK: - Records Section
    @ViewBuilder
    private func dayModeRecordsSection() -> some View {
        VStack(alignment: .leading, spacing: dayModeCardSpacing) {
            ForEach(records()) { rec in
                recordRow(rec)
            }
        }
    }
    @ViewBuilder
    private func recordRow(_ rec: SessionRecord) -> some View {
        let isDeleted = historyVM.isDeleted(sessionManager: sessionManager, sessionName: rec.sessionName)
        let displayName = historyVM.displaySessionName(sessionManager: sessionManager, sessionName: rec.sessionName)
        HStack(spacing: 0) {
            timeRangeView(rec)
            Spacer(minLength: 8)
            activityInfoView(displayName: displayName, rec: rec, isDeleted: isDeleted)
            actionButtonView(rec: rec, isDeleted: isDeleted)
        }
        .font(DesignTokens.Fonts.label)
        .frame(minHeight: dayModeCardHeight, alignment: .leading)
        .padding(.horizontal, DesignTokens.Padding.cardHorizontal)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
    }
    @ViewBuilder
    private func timeRangeView(_ rec: SessionRecord) -> some View {
        Text(rec.start.formatted(date: .omitted, time: .shortened))
            .monospacedDigit()
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
        Spacer().frame(width: 8)
        Image(systemName: "arrow.right")
            .font(DesignTokens.Fonts.caption)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
        Spacer().frame(width: 8)
        Text(rec.end.formatted(date: .omitted, time: .shortened))
            .monospacedDigit()
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
    }
    @ViewBuilder
    private func activityInfoView(displayName: String, rec: SessionRecord, isDeleted: Bool) -> some View {
        Text("\(displayName) \(durationSeconds(rec) / 60) min")
            .foregroundColor(isDeleted ? DesignTokens.MoonColors.textMuted : DesignTokens.MoonColors.textPrimary)
            .opacity(isDeleted ? 0.5 : 1.0)
    }
    @ViewBuilder
    private func actionButtonView(rec: SessionRecord, isDeleted: Bool) -> some View {
        if isDeleted {
            restoreButton(rec: rec)
        } else if !inlineReflectionEnabled {
            memoButton(rec: rec)
        }
    }
    @ViewBuilder
    private func restoreButton(rec: SessionRecord) -> some View {
        Button("Restore") {
            do {
                try historyVM.restore(record: rec, sessionManager: sessionManager)
            } catch {
                restoreError = error.localizedDescription
                showRestoreAlert = true
            }
        }
        .font(DesignTokens.Fonts.caption)
        .foregroundColor(DesignTokens.MoonColors.accentBlue)
    }
    @ViewBuilder
    private func memoButton(rec: SessionRecord) -> some View {
        let hasMemo = rec.memo?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let iconName = hasMemo ? "pencil" : "plus"
        Button(
            action: {
                selectedRecordForMemoEdit = rec
            },
            label: {
                Image(systemName: iconName)
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.accentBlue)
            }
        )
    }
    // MARK: - Data Methods
    private func records() -> [SessionRecord] {
        return dataProvider.records(historyVM: historyVM, targetDate: targetDate)
    }
    private func totalSeconds() -> Int {
        return dataProvider.totalSeconds(historyVM: historyVM, targetDate: targetDate)
    }
    private func durationSeconds(_ rec: SessionRecord) -> Int {
        return dataProvider.durationSeconds(rec)
    }
    // MARK: - Summary Sections
    private func byActivity() -> [LabelSummary] {
        return dataProvider.byActivity(historyVM: historyVM, targetDate: targetDate)
    }
    private func bySubtitle() -> [LabelSummary] {
        return dataProvider.bySubtitle(historyVM: historyVM, targetDate: targetDate)
    }
    @ViewBuilder
    private func activitySummarySection() -> some View {
        sectionBuilder.activitySummarySection(summaries: byActivity())
    }
    @ViewBuilder
    private func subtitleSummarySection() -> some View {
        if !bySubtitle().isEmpty {
            sectionBuilder.subtitleSummarySection(summaries: bySubtitle())
        }
    }

    private func memoSection() -> some View {
        let recordsWithMemos = recordsWithMemos()
        let onMemoEditClosure: (SessionRecord) -> Void = { record in
            self.selectRecordForMemoEdit(record)
        }

        // DailyTimelineSectionBuilderを直接インスタンス化
        let sectionBuilder = DailyTimelineSectionBuilder()

        return sectionBuilder.memoSection(records: recordsWithMemos, onMemoEdit: onMemoEditClosure)
    }

    private func recordsWithMemos() -> [SessionRecord] {
        return dataProvider.recordsWithMemos(historyVM: historyVM, targetDate: targetDate)
    }

    // MARK: - Inline Reflection Views

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

    // MARK: - Memo Edit
    private func selectRecordForMemoEdit(_ record: SessionRecord) {
        selectedRecordForMemoEdit = record
    }

}

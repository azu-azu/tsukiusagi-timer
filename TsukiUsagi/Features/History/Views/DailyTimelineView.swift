import SwiftUI
import Foundation
struct DailyTimelineView: View {
    let targetDate: Date
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    // 新しいViewModelとBuilder（既存コードと並行動作）
    @StateObject private var viewModel: DailyTimelineViewModel
    private let sectionBuilder = DailyTimelineSectionBuilder()
    private let gestureHandler = DailyTimelineGestureHandler()
    private let dataProvider = DailyTimelineDataProvider()

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
    }
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Total 表示
                TotalCard(text: TimeFormatters.totalText(viewModel.totalMinutes(historyVM: historyVM)))
                // レコード表示
                sectionBuilder.dayModeRecordsSection(
                    records: viewModel.records(historyVM: historyVM),
                    onRestore: { record in
                        viewModel.restoreRecord(record, historyVM: historyVM, sessionManager: sessionManager)
                    },
                    onMemoEdit: { record in
                        viewModel.selectRecordForMemoEdit(record)
                    }
                )
                // 集計表示（レコードが複数ある場合のみ）
                if viewModel.records(historyVM: historyVM).count > 1 {
                    sectionBuilder.activitySummarySection(summaries: viewModel.byActivity(historyVM: historyVM))
                    sectionBuilder.subtitleSummarySection(summaries: viewModel.bySubtitle(historyVM: historyVM))
                }
                // メモ部分
                sectionBuilder.memoSection(
                    records: viewModel.recordsWithMemos(historyVM: historyVM),
                    onMemoEdit: { record in
                        viewModel.selectRecordForMemoEdit(record)
                    }
                )
            }
            .padding(.horizontal)
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
        .sheet(item: $selectedRecordForMemoEdit) { record in
            MemoEditView(record: record)
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        .onAppear {
            // View Details画面ではbackスワイプを有効化
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                enableBackSwipeGesture()
            }
        }
        .onDisappear {
            // History画面に戻る際はbackスワイプを無効化
            disableBackSwipeGesture()
        }
    }
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
        let isDeleted = historyVM.isDeleted(sessionManager: sessionManager, activity: rec.activity)
        let displayName = historyVM.displayActivity(sessionManager: sessionManager, activity: rec.activity)
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
        Text("\(displayName) \(durationMinutes(rec)) min")
            .foregroundColor(isDeleted ? DesignTokens.MoonColors.textMuted : DesignTokens.MoonColors.textPrimary)
            .opacity(isDeleted ? 0.5 : 1.0)
    }
    @ViewBuilder
    private func actionButtonView(rec: SessionRecord, isDeleted: Bool) -> some View {
        if isDeleted {
            restoreButton(rec: rec)
        } else {
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
    private func totalMinutes() -> Int {
        return dataProvider.totalMinutes(historyVM: historyVM, targetDate: targetDate)
    }
    private func durationMinutes(_ rec: SessionRecord) -> Int {
        return dataProvider.durationMinutes(rec)
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
    @ViewBuilder
    private func memoSection() -> some View {
        let recordsWithMemos = recordsWithMemos()
        if !recordsWithMemos.isEmpty {
            sectionBuilder.memoSection(records: recordsWithMemos, onMemoEdit: selectRecordForMemoEdit)
        }
    }
    private func recordsWithMemos() -> [SessionRecord] {
        return dataProvider.recordsWithMemos(historyVM: historyVM, targetDate: targetDate)
    }

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

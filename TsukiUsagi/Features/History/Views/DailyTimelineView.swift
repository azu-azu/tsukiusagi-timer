import SwiftUI
import Foundation

struct DailyTimelineView: View {
    let targetDate: Date
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var sessionManager: SessionManager

    @State private var restoreError: String?
    @State private var showRestoreAlert = false

    private let cal = Calendar.current
    private let dayModeCardHeight: CGFloat = 40
    private let dayModeCardSpacing: CGFloat = 2
    private let timeWidth: CGFloat = 100
    private let summaryCardHeight: CGFloat = 50

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Total 表示
                TotalCard(text: TimeFormatters.totalText(totalMinutes()))

                // レコード表示
                dayModeRecordsSection()

                // 集計表示（レコードが複数ある場合のみ）
                if records().count > 1 {
                    activitySummarySection()
                    subtitleSummarySection()
                }

                // メモ部分
                memoSection()
            }
            .padding(.horizontal)
        }
        .simultaneousGesture(
            // 左端からのスワイプを確実に認識
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    // 左端から右方向へのスワイプを検出
                    if value.startLocation.x < 50 && value.translation.width > 100 {
                        // ナビゲーションを戻す
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            findNavigationController(in: window.rootViewController)?.popViewController(animated: true)
                        }
                    }
                }
        )
        .navigationTitle(targetDate.formatted(.dateTime.weekday(.wide).month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showRestoreAlert) {
            Alert(
                title: Text("Restore Error"),
                message: Text(restoreError ?? ""),
                dismissButton: .default(Text("OK"))
            )
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

            Spacer(minLength: 8)

            Text("\(displayName) \(durationMinutes(rec)) min")
                .foregroundColor(isDeleted ? DesignTokens.MoonColors.textMuted : DesignTokens.MoonColors.textPrimary)
                .opacity(isDeleted ? 0.5 : 1.0)

            if isDeleted {
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
        }
        .font(DesignTokens.Fonts.label)
        .frame(minHeight: dayModeCardHeight, alignment: .leading)
        .padding(.horizontal, DesignTokens.Padding.cardHorizontal)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
    }

    // MARK: - Data Methods

    private func records() -> [SessionRecord] {
        return historyVM.history
            .filter { rec in
                cal.isDate(rec.start, inSameDayAs: targetDate)
            }
            .sorted { $0.start < $1.start }
    }

    private func totalMinutes() -> Int {
        records().reduce(0) { $0 + durationMinutes($1) }
    }

    private func durationMinutes(_ rec: SessionRecord) -> Int {
        let sec = rec.end.timeIntervalSince(rec.start)
        return max(Int(sec) / 60, 1)
    }

    // MARK: - Summary Sections

    private struct LabelSummary {
        let label: String
        let total: Int
    }

    private func byActivity() -> [LabelSummary] {
        let grouped = Dictionary(grouping: records(), by: \.activity)
        return grouped.map { k, recs in
            LabelSummary(
                label: String(describing: k),
                total: recs.reduce(0) { $0 + durationMinutes($1) }
            )
        }
        .sorted { $0.total > $1.total }
    }

    private func bySubtitle() -> [LabelSummary] {
        let recordsWithSubtitle = records().filter {
            guard let subtitle = $0.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
            return !subtitle.isEmpty
        }
        let grouped = Dictionary(grouping: recordsWithSubtitle) { $0.subtitle! }
        return grouped.map { k, recs in
            LabelSummary(
                label: k,
                total: recs.reduce(0) { $0 + durationMinutes($1) }
            )
        }
        .sorted { $0.total > $1.total }
    }

    @ViewBuilder
    private func activitySummarySection() -> some View {
        summarySection(title: "By Activity", summaries: byActivity())
    }

    @ViewBuilder
    private func subtitleSummarySection() -> some View {
        if !bySubtitle().isEmpty {
            summarySection(title: "By Subtitle", summaries: bySubtitle())
        }
    }

    private func summarySection(title: String, summaries: [LabelSummary]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            ForEach(summaries, id: \.label) { s in
                HStack {
                    Text(s.label)
                        .padding(.leading, 8)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    Spacer()
                    Text(TimeFormatters.totalText(s.total))
                        .monospacedDigit()
                        .frame(width: timeWidth, alignment: .trailing)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }
                .summaryCardStyle(height: summaryCardHeight)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private func memoSection() -> some View {
        let memos = records()
            .compactMap { $0.memo?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !memos.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("📝 Memos")
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)

                ForEach(memos, id: \.self) { memo in
                    Text(memo)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .padding(8)
                        .roundedCard()
                }
            }
            .padding(.top, 16)
        }
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
}

// 共通サマリーカードスタイル
extension View {
    func summaryCardStyle(
        height: CGFloat = 32,
        cornerRadius: CGFloat = 6,
        backgroundColor: Color = DesignTokens.CosmosColors.cardBackground,
        padding: EdgeInsets = EdgeInsets(
            top: 4,
            leading: DesignTokens.Padding.cardHorizontal,
            bottom: 4,
            trailing: DesignTokens.Padding.cardHorizontal
        )
    ) -> some View {
        font(DesignTokens.Fonts.label)
            .padding(padding)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
    }
}

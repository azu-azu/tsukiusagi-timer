import SwiftUI

struct MemoEditView: View {
    let record: SessionRecord
    /// Anchor date for new reflections so they appear in the opened day's details
    let anchorDate: Date?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel

    @State private var editedMemo: String = ""
    @State private var isKeyboardVisible: Bool = false
    @State private var keyboardBottomInset: CGFloat = 0

    @FocusState private var isMemoFocused: Bool

    private let memoEditorMaxHeight: CGFloat = 300

    // 新規追加かどうかを判定
    private var isNewRecord: Bool {
        return record.sessionName == "New Reflection" && (record.memo?.isEmpty ?? true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.CosmosColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // セッション情報表示
                        sessionInfoSection()

                        // Memo編集セクション
                        memoEditSection()

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: keyboardBottomInset)
                }
            }
            .navigationTitle(
                isNewRecord
                ? NSLocalizedString("history_memo_add_reflection", comment: "Add reflection title")
                : NSLocalizedString("history_memo_edit_reflection", comment: "Edit reflection title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Copy.Button.cancel) {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Copy.Button.save) {
                        saveMemo()
                    }
                    .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    .fontWeight(.semibold)
                }
            }
            .presentationBackground(DesignTokens.CosmosColors.background)
            .background(DesignTokens.CosmosColors.background)
            .onAppear {
                editedMemo = record.memo ?? ""
                // モーダル表示時に自動でmemoにフォーカス
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isMemoFocused = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isKeyboardVisible = true
                }
                if let info = (notif as Notification).userInfo,
                    let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    let screenMaxY = UIScreen.main.bounds.maxY
                    let overlap = max(0, screenMaxY - frame.minY)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        keyboardBottomInset = overlap
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isKeyboardVisible = false
                    keyboardBottomInset = 0
                }
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private func sessionInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("history_memo_session_info", comment: "Session info section title"))
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            sessionInfoContent()
        }
    }

    @ViewBuilder
    private func sessionInfoContent() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            activityInfoRow()

        if let task = record.task, !task.isEmpty {
            taskInfoRow(task: task)
        }

            durationInfoRow()
            timeInfoRow()
        }
        .padding(12)
        .background(DesignTokens.CosmosColors.cardBackground)
        .cornerRadius(8)
    }

    @ViewBuilder
    private func activityInfoRow() -> some View {
        HStack {
            Text(NSLocalizedString("history_memo_session", comment: "Session label"))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
            Spacer()
            Text(record.sessionName)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
        }
    }

    @ViewBuilder
    private func taskInfoRow(task: String) -> some View {
        HStack {
            Text(NSLocalizedString("history_memo_task", comment: "Task label"))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
            Spacer()
            Text(task)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
        }
    }

    @ViewBuilder
    private func durationInfoRow() -> some View {
        HStack {
            Text(NSLocalizedString("history_memo_duration", comment: "Duration label"))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
            Spacer()
            Text(TimeFormatters.totalText(Int(record.duration / 60)))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func timeInfoRow() -> some View {
        HStack {
            Text(Copy.Label.time)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
            Spacer()
            Text("\(record.start.formatted(date: .omitted, time: .shortened)) - " +
                 "\(record.end.formatted(date: .omitted, time: .shortened))")
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func memoEditSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("history_memo_reflection", comment: "Reflection section title"))
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            TextEditor(text: $editedMemo)
                .frame(minHeight: 120, maxHeight: memoEditorMaxHeight)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(DesignTokens.WhiteColors.surface)
                .cornerRadius(6)
                .focused($isMemoFocused)
                .overlay(
                    // プレースホルダー
                    Group {
                        if editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack {
                                VStack {
                                    Text(
                                        NSLocalizedString(
                                            "history_memo_add_reflection_placeholder",
                                            comment: "Add reflection placeholder"
                                        )
                                    )
                                        .lineLimit(nil)
                                        .font(DesignTokens.Fonts.label)
                                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                        }
                    }
                )
        }
    }

    // MARK: - Private Methods

    private func saveMemo() {
        let trimmedMemo = editedMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalMemo = trimmedMemo.isEmpty ? nil : trimmedMemo

        if isNewRecord {
            // 新規追加の場合
            if let finalMemo = finalMemo {
                // 新規反映は詳細画面の対象日に紐付ける
                let now = Date()
                let startOnTarget = anchoredDateTime(baseDay: anchorDate ?? record.start, timeOf: now)
                let endOnTarget = startOnTarget.addingTimeInterval(60) // 1分幅でソート上の視認性を確保
                let newRecord = SessionRecord(
                    id: UUID().uuidString,
                    start: startOnTarget,
                    end: endOnTarget,
                    phase: .focus,
                    sessionName: "Reflection",
                    task: nil,
                    memo: finalMemo,
                    completedSilently: nil
                )
                historyVM.addRecord(newRecord)
            }
        } else {
            // 既存レコードの更新
            historyVM.updateMemo(for: record.id, newMemo: finalMemo)
        }

        dismiss()
    }

    /// 指定日の年月日に、指定時刻（now）の時分秒を合成して返す
    private func anchoredDateTime(baseDay: Date, timeOf now: Date) -> Date {
        let cal = Calendar.current
        let day = cal.dateComponents([.year, .month, .day], from: baseDay)
        let tod = cal.dateComponents([.hour, .minute, .second], from: now)
        var comps = DateComponents()
        comps.year = day.year
        comps.month = day.month
        comps.day = day.day
        comps.hour = tod.hour
        comps.minute = tod.minute
        comps.second = tod.second
        return cal.date(from: comps) ?? baseDay
    }
}

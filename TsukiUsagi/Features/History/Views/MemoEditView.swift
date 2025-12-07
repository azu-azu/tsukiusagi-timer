import SwiftUI

struct MemoEditView: View {
    let record: SessionRecord
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var historyVM: HistoryViewModel

    @State private var editedMemo: String = ""
    @State private var isKeyboardVisible: Bool = false
    @State private var keyboardBottomInset: CGFloat = 0

    @FocusState private var isMemoFocused: Bool

    private let memoEditorMaxHeight: CGFloat = 300

    // 新規追加かどうかを判定
    private var isNewRecord: Bool {
        return false // legacy path removed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.SkyToneColors.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // セッション情報表示
                        sessionInfoSection()

                        // Memo編集セクション
                        memoEditSection()

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: keyboardBottomInset)
                }
            }
            .navigationTitle(Labels.Sections.editReflection)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Copy.Button.cancel) {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Copy.Button.save) {
                        saveMemo()
                    }
                    .foregroundColor(DesignTokens.MoonColors.accentBlue)
                    .fontWeight(.semibold)
                }
            }
            .presentationBackground(DesignTokens.SkyToneColors.nightStart)
            .background(DesignTokens.SkyToneColors.nightStart)
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
            Text(Labels.Sections.sessionInfo)
                .font(DesignTokens.Fonts.sectionTitle)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

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
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.SkyToneColors.cardGradient)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.SkyToneColors.cardBorderGradient, lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private func activityInfoRow() -> some View {
        HStack {
            Text(Labels.InfoRow.session)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textTertiary)
            Spacer()
            Text(record.sessionName)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
        }
    }

    @ViewBuilder
    private func taskInfoRow(task: String) -> some View {
        HStack {
            Text(Labels.InfoRow.task)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textTertiary)
            Spacer()
            Text(task)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
        }
    }

    @ViewBuilder
    private func durationInfoRow() -> some View {
        HStack {
            Text(Labels.InfoRow.duration)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textTertiary)
            Spacer()
            Text(TimeFormatters.totalText(Int(record.duration / 60)))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func timeInfoRow() -> some View {
        HStack {
            Text(Copy.Label.time)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textTertiary)
            Spacer()
            Text("\(record.start.formatted(date: .omitted, time: .shortened)) - " +
                 "\(record.end.formatted(date: .omitted, time: .shortened))")
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func memoEditSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Labels.Sections.reflection)
                .font(DesignTokens.Fonts.sectionTitle)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

            TextEditor(text: $editedMemo)
                .frame(minHeight: 120, maxHeight: memoEditorMaxHeight)
                .padding(12)
                .scrollContentBackground(.hidden)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignTokens.SkyToneColors.cardGradient)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignTokens.SkyToneColors.cardBorderGradient, lineWidth: 1)
                    }
                )
                .focused($isMemoFocused)
                .overlay(
                    // プレースホルダー
                    Group {
                        if editedMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack {
                                VStack {
                                    Text(Messages.Placeholders.addReflection)
                                        .lineLimit(nil)
                                        .font(DesignTokens.Fonts.label)
                                        .foregroundColor(DesignTokens.SkyToneColors.textQuinary)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Private Methods

    private func saveMemo() {
        let trimmedMemo = editedMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalMemo = trimmedMemo.isEmpty ? nil : trimmedMemo

        // 既存レコードの更新のみサポート（legacy new-record path removed)
        historyVM.updateMemo(for: record.id, newMemo: finalMemo)

        dismiss()
    }
}

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
            .navigationTitle("Edit Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
            Text("Session Info")
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Activity:")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    Spacer()
                    Text(record.activity)
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                }

                if let subtitle = record.subtitle, !subtitle.isEmpty {
                    HStack {
                        Text("Description:")
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        Spacer()
                        Text(subtitle)
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    }
                }

                HStack {
                    Text("Duration:")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    Spacer()
                    Text(TimeFormatters.totalText(Int(record.duration / 60)))
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)
                        .monospacedDigit()
                }

                HStack {
                    Text("Time:")
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
            .padding(12)
            .background(DesignTokens.CosmosColors.cardBackground)
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func memoEditSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memo")
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
                                    Text("Add a memo for this session...")
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

        historyVM.updateMemo(for: record.id, newMemo: finalMemo)
        dismiss()
    }
}

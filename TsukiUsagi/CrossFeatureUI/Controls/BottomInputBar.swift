//
//  BottomInputBar.swift
//  TsukiUsagi
//
//  下部入力バーコンポーネント
//  責務：
//    - チャット風の入力UI提供
//    - テキストエディタ + 拡大ボタン + 送信ボタン
//    - キーボード上に固定表示
//    - SaveModeによる保存タイミング制御
//

import SwiftUI

/// チャット風の下部入力バー
/// 画面下部に固定され、キーボードと連動する
struct BottomInputBar: View {
    /// 保存モード
    enum SaveMode {
        /// 毎キーストロークで即時反映（従来の動作）
        case immediate
        /// 送信ボタンでのみ反映（一時変数で編集）
        case onSubmit
    }

    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let placeholder: LocalizedStringKey
    let saveMode: SaveMode
    let onExpand: () -> Void
    let onSubmit: (() -> Void)?

    /// 内部編集用テキスト（saveMode == .onSubmit時に使用）
    @State private var editingText: String = ""

    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        placeholder: LocalizedStringKey,
        saveMode: SaveMode = .onSubmit,
        onExpand: @escaping () -> Void,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.saveMode = saveMode
        self.onExpand = onExpand
        self.onSubmit = onSubmit
    }

    /// 実際に表示・編集するテキストのバインディング
    private var activeTextBinding: Binding<String> {
        switch saveMode {
        case .immediate:
            return $text
        case .onSubmit:
            return $editingText
        }
    }

    /// 表示用テキスト（空判定などに使用）
    private var displayText: String {
        switch saveMode {
        case .immediate:
            return text
        case .onSubmit:
            return editingText
        }
    }

    private var isTextEmpty: Bool {
        displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// テキストの行数（改行で分割）
    private var lineCount: Int {
        displayText.components(separatedBy: "\n").count
    }

    /// 拡大ボタンを表示するか（3行以上）
    private var shouldShowExpandButton: Bool {
        lineCount >= 3
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // テキスト入力エリア（ボタン内蔵）
            textInputArea
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            // onSubmitモードでは初期値をコピー
            if saveMode == .onSubmit {
                editingText = text
            }
        }
    }

    private func handleSubmit() {
        guard !isTextEmpty else { return }
        // onSubmitモードでは内部テキストを外部バインディングに反映
        if saveMode == .onSubmit {
            text = editingText
        }
        if let onSubmit {
            onSubmit()
        } else {
            isFocused = false
            Keyboard.dismiss()
        }
    }

    /// 拡大ボタン押下時（onSubmitモードでは内部テキストを反映してから拡大）
    private func handleExpand() {
        if saveMode == .onSubmit {
            text = editingText
        }
        onExpand()
    }

    @ViewBuilder
    private var textInputArea: some View {
        ZStack(alignment: .topLeading) {
            // TextEditor
            TextEditor(text: activeTextBinding)
                .focused($isFocused)
                .frame(minHeight: 36, maxHeight: 120)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 12)
                .padding(.trailing, 44) // ボタン用スペース
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .overlay(alignment: .topTrailing) {
                    if shouldShowExpandButton {
                        expandButton
                            .padding(.top, 12)
                            .padding(.trailing, 12)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    submitButton
                        .padding(.bottom, 6)
                        .padding(.trailing, 6)
                }

            // プレースホルダー
            if isTextEmpty {
                Text(placeholder)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.SkyToneColors.textQuinary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var expandButton: some View {
        Button {
            handleExpand()
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignTokens.SkyToneColors.textTertiary)
        }
        .accessibilityLabel(LocalizedStringKey("expand_editor"))
    }

    @ViewBuilder
    private var submitButton: some View {
        Button {
            handleSubmit()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(
                    isTextEmpty
                        ? DesignTokens.SkyToneColors.textQuinary
                        : DesignTokens.SkyToneColors.accentBlue
                )
        }
        .disabled(isTextEmpty)
        .accessibilityLabel(LocalizedStringKey("submit"))
    }
}

/// 編集可能フィールドのプレースホルダーカード
/// タップで入力バーを表示する
struct EditablePlaceholderCard: View {
    let text: String
    let placeholder: LocalizedStringKey
    let isEditing: Bool
    let isDuplicate: Bool
    let onTap: () -> Void
    let onDelete: (() -> Void)?

    init(
        text: String,
        placeholder: LocalizedStringKey,
        isEditing: Bool,
        isDuplicate: Bool = false,
        onTap: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholder = placeholder
        self.isEditing = isEditing
        self.isDuplicate = isDuplicate
        self.onTap = onTap
        self.onDelete = onDelete
    }

    var body: some View {
        let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        HStack(spacing: DesignTokens.Spacing.medium) {
            Button(action: onTap) {
                ZStack {
                    // 通常コンテンツ
                    HStack {
                        if isEmpty {
                            Text(placeholder)
                                .font(DesignTokens.Fonts.label)
                                .foregroundColor(DesignTokens.SkyToneColors.textQuinary)
                        } else {
                            Text(text)
                                .font(DesignTokens.Fonts.label)
                                .foregroundColor(
                                    isDuplicate
                                        ? DesignTokens.UtilityColors.duplicateWarning
                                        : DesignTokens.SkyToneColors.textPrimary
                                )
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                    }
                    .opacity(isEditing ? 0 : 1)

                    // 編集中インジケータ
                    if isEditing {
                        editingIndicator
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, isEmpty ? 12 : 16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isDuplicate
                                    ? DesignTokens.UtilityColors.duplicateWarning
                                    : Color.white.opacity(0.1),
                                lineWidth: isDuplicate ? 2 : 1
                            )
                    }
                )
            }
            .buttonStyle(.plain)
            .opacity(isEditing ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isEditing)
            .allowsHitTesting(!isEditing)

            // 削除ボタン（編集中でなければ表示）
            if let onDelete, !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(DesignTokens.SkyToneColors.accentOrange)
                        .font(DesignTokens.Fonts.symbolMedium)
                }
            }
        }
    }

    @ViewBuilder
    private var editingIndicator: some View {
        HStack(spacing: 6) {
            PencilIcon(size: .small)
            Text("editing_below")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

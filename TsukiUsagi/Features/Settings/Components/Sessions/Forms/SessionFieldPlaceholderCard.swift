//
//  SessionFieldPlaceholderCard.swift
//  TsukiUsagi
//
//  Created by Claude on 2025/01/01.
//

import SwiftUI

/// セッションフィールドのプレースホルダーカード（タップで入力バーを表示）
struct SessionFieldPlaceholderCard: View {
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
                                .foregroundColor(DesignTokens.MoonColors.textMuted)
                        } else {
                            Text(text)
                                .font(DesignTokens.Fonts.label)
                                .foregroundColor(
                                    isDuplicate
                                        ? DesignTokens.UtilityColors.duplicateWarning
                                        : DesignTokens.MoonColors.textPrimary
                                )
                                .lineLimit(1)
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
                .padding(.horizontal, 12)
                .padding(.vertical, isEmpty ? 12 : 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.CosmosColors.cardBackground)
                .cornerRadius(DesignTokens.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(
                            isDuplicate
                                ? DesignTokens.UtilityColors.duplicateWarning
                                : DesignTokens.BlackColors.stroke,
                            lineWidth: isDuplicate ? 2 : 1
                        )
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
                        .foregroundColor(DesignTokens.MoonColors.accentOrange)
                        .font(DesignTokens.Fonts.symbolMedium)
                }
            }
        }
    }

    @ViewBuilder
    private var editingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil")
                .font(DesignTokens.Fonts.symbolSmall)
            Text("reflection_editing_below")
                .font(DesignTokens.Fonts.caption)
        }
        .foregroundColor(DesignTokens.MoonColors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#if DEBUG
struct SessionFieldPlaceholderCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SessionFieldPlaceholderCard(
                text: "",
                placeholder: "Enter session name",
                isEditing: false,
                onTap: {}
            )

            SessionFieldPlaceholderCard(
                text: "Work",
                placeholder: "Enter session name",
                isEditing: false,
                onTap: {}
            )

            SessionFieldPlaceholderCard(
                text: "Work",
                placeholder: "Enter session name",
                isEditing: true,
                onTap: {}
            )

            SessionFieldPlaceholderCard(
                text: "Duplicate Task",
                placeholder: "Enter task",
                isEditing: false,
                isDuplicate: true,
                onTap: {},
                onDelete: {}
            )
        }
        .padding()
        .background(DesignTokens.CosmosColors.background)
    }
}
#endif

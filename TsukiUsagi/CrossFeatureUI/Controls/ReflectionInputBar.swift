//
//  ReflectionInputBar.swift
//  TsukiUsagi
//
//  Created by Claude on 2025/01/01.
//

import SwiftUI

/// チャット風のReflection入力バー
/// 画面下部に固定され、キーボードと連動する
struct ReflectionInputBar: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let placeholder: LocalizedStringKey
    let onExpand: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // テキスト入力エリア
            textInputArea

            // 拡大ボタン
            expandButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(DesignTokens.SkyToneColors.nightStart)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: -4)
        )
    }

    @ViewBuilder
    private var textInputArea: some View {
        ZStack(alignment: .topLeading) {
            // TextEditor
            TextEditor(text: $text)
                .focused($isFocused)
                .frame(minHeight: 36, maxHeight: 120)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
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

            // プレースホルダー
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
            onExpand()
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(DesignTokens.Fonts.symbolMedium)
                .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
        }
        .accessibilityLabel(LocalizedStringKey("expand_editor"))
    }
}

/// Reflectionエリアのプレースホルダー表示（タップで入力バーを表示）
struct ReflectionPlaceholderCard: View {
    let text: String
    let placeholder: LocalizedStringKey
    let isEditing: Bool
    let onTap: () -> Void

    var body: some View {
        let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

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
                            .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
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
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            )
        }
        .buttonStyle(.plain)
        .opacity(isEditing ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .allowsHitTesting(!isEditing)
    }

    @ViewBuilder
    private var editingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "pencil")
                .font(DesignTokens.Fonts.symbolSmall)
            Text("reflection_editing_below")
                .font(DesignTokens.Fonts.caption)
        }
        .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

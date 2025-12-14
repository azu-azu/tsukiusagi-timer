//
//  BottomInputBarContainer.swift
//  TsukiUsagi
//
//  下部入力バー付きコンテナ
//  責務：
//    - 入力バーの表示/非表示管理
//    - 外側タップで入力バーを閉じる挙動
//    - スクロール時のキーボード連携
//    - 入力バーとキーボードの位置関係統一
//

import SwiftUI

/// 下部入力バー付きの汎用コンテナ
///
/// Reflection画面とSettings画面で共通の入力バー挙動を提供
/// - 入力バーはキーボード上に固定表示
/// - 外側タップで入力バーを閉じる
/// - スクロールでキーボードを閉じる（interactively）
struct BottomInputBarContainer<Content: View>: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    @FocusState.Binding var isFocused: Bool
    let placeholder: LocalizedStringKey
    let onExpand: () -> Void
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    guard isEditing else { return }
                    closeInputBar()
                }
            )
            .safeAreaInset(edge: .bottom) {
                if isEditing {
                    BottomInputBar(
                        text: $text,
                        isFocused: $isFocused,
                        placeholder: placeholder,
                        onExpand: onExpand
                    )
                }
            }
            .onChange(of: isEditing) { _, newValue in
                if newValue {
                    // 編集開始時にフォーカスを設定
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
            }
    }

    private func closeInputBar() {
        isFocused = false
        onClose()
        Task { @MainActor in
            Keyboard.dismiss()
        }
    }
}

//
//  EditableModal.swift
//  TsukiUsagi
//
//  共通モーダルコンポーネント
//  責務：
//    - モーダルタイトル表示
//    - Save / Cancel のツールバー操作
//    - キーボードCloseボタン制御
//    - モーダルのレイアウトスタイル提供
//    - 再利用可能なGeneric Content受け入れ
//

import SwiftUI

/// 再利用可能な編集モーダルUI
///
/// Generic Contentを受け取ることで、様々な編集機能で再利用可能
/// 統一されたナビゲーション構造とボタン配置を提供
struct EditableModal<Content: View>: View {
    let title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    let content: () -> Content
    let isKeyboardCloseVisible: Bool
    let onKeyboardClose: () -> Void

    /// EditableModalの初期化
    /// - Parameters:
    ///   - title: モーダルのタイトル
    ///   - onSave: 保存ボタンタップ時のアクション
    ///   - onCancel: キャンセルボタンタップ時のアクション
    ///   - isKeyboardCloseVisible: キーボード閉じるボタンの表示状態
    ///   - onKeyboardClose: キーボード閉じるボタンタップ時のアクション
    ///   - content: モーダル内に表示するコンテンツView
    init(
        title: String,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        isKeyboardCloseVisible: Bool,
        onKeyboardClose: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.onSave = onSave
        self.onCancel = onCancel
        self.isKeyboardCloseVisible = isKeyboardCloseVisible
        self.onKeyboardClose = onKeyboardClose
        self.content = content
    }

    var body: some View {
        NavigationView {
            VStack {
                content()
                Spacer()
            }
            .padding()
            .background(Color.cosmosBackground.ignoresSafeArea())
            .keyboardCloseButton(
                isVisible: isKeyboardCloseVisible,
                action: onKeyboardClose
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .background(Color.cosmosBackground.ignoresSafeArea())
        .interactiveDismissDisabled() // 意図しない閉じ操作を防ぐ
    }
}

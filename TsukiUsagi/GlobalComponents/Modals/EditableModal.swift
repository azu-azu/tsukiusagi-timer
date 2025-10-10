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
    let isSaveDisabled: Bool
    let onCancel: () -> Void
    let content: () -> Content
    let isKeyboardCloseVisible: Bool
    let onKeyboardClose: () -> Void
    @Binding var focusedRowID: UUID?

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
        isSaveDisabled: Bool = false,
        isKeyboardCloseVisible: Bool,
        onKeyboardClose: @escaping () -> Void,
        focusedRowID: Binding<UUID?> = .constant(nil),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.onSave = onSave
        self.isSaveDisabled = isSaveDisabled
        self.onCancel = onCancel
        self.isKeyboardCloseVisible = isKeyboardCloseVisible
        self.onKeyboardClose = onKeyboardClose
        self.content = content
        self._focusedRowID = focusedRowID
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                        content()
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .keyboardAwareInset(baseBottomPadding: 16)
                .dismissKeyboardOnTap {
                    onKeyboardClose()
                }
                .onChange(of: focusedRowID) { _, newValue in
                    scrollToID(proxy, id: newValue)
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIResponder.keyboardWillChangeFrameNotification
                    )
                ) { _ in
                    scrollToID(proxy, id: focusedRowID)
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIResponder.keyboardDidChangeFrameNotification
                    )
                ) { _ in
                    scrollToID(proxy, id: focusedRowID, extraDelay: 0.08)
                }
            }
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
                        .disabled(isSaveDisabled)
                        .allowsHitTesting(!isSaveDisabled)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        onKeyboardClose()
                    } label: {
                        Label("Close", systemImage: "keyboard.chevron.compact.down")
                    }
                }
            }
            .keyboardCloseButton(
                isVisible: isKeyboardCloseVisible,
                action: onKeyboardClose
            )
        }
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        .interactiveDismissDisabled() // 意図しない閉じ操作を防ぐ
    }
}

private extension EditableModal {
    func scrollToID(_ proxy: ScrollViewProxy, id: UUID?, extraDelay: Double = 0) {
        guard let id else { return }

        DispatchQueue.main.async {
            withAnimation(.none) {
                proxy.scrollTo(id, anchor: .center)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 + extraDelay) {
            withAnimation(.easeInOut) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
}

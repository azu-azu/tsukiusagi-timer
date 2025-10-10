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
    enum EnsureVisibleMode {
        case none               // 強制スクロールしない
        case centerAggressive   // 既存挙動：常にcenterへ寄せる
        case bottomIfObscuredOnce // 推奨：必要時だけ一回.bottomへ
    }

    let title: String
    let onSave: () -> Void
    let isSaveDisabled: Bool
    let onCancel: () -> Void
    let content: () -> Content
    let isKeyboardCloseVisible: Bool
    let onKeyboardClose: () -> Void
    @Binding var focusedRowID: UUID?
    let ensureVisibleMode: EnsureVisibleMode

    @State private var lastEnsureAt: Date = .distantPast
    @State private var bottomLift: CGFloat = 0
    @State private var focusedBottomY: CGFloat = 0
    @State private var keyboardEndFrame: CGRect = .zero

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
        ensureVisibleMode: EnsureVisibleMode = .centerAggressive,
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
        self.ensureVisibleMode = ensureVisibleMode
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
                .keyboardAwareInset(baseBottomPadding: ensureVisibleMode == .none ? 0 : 16)
                .dismissKeyboardOnTap {
                    onKeyboardClose()
                }
                .onPreferenceChange(FocusedRowBottomPrefKey.self) { value in
                    focusedBottomY = value
                    recomputeBottomLift()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: bottomLift)
                }
                .onChange(of: focusedRowID) { _, newValue in
                    switch ensureVisibleMode {
                    case .centerAggressive:
                        scrollToID(proxy, id: newValue)
                    case .bottomIfObscuredOnce:
                        ensureVisibleOnceBottom(proxy, id: newValue)
                    case .none:
                        recomputeBottomLift()
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIResponder.keyboardWillChangeFrameNotification
                    )
                ) { notification in
                    if let v = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                        keyboardEndFrame = v.cgRectValue
                    }
                    switch ensureVisibleMode {
                    case .centerAggressive:
                        scrollToID(proxy, id: focusedRowID)
                    case .bottomIfObscuredOnce:
                        ensureVisibleOnceBottom(proxy, id: focusedRowID)
                    case .none:
                        recomputeBottomLift()
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIResponder.keyboardDidChangeFrameNotification
                    )
                ) { notification in
                    if let v = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                        keyboardEndFrame = v.cgRectValue
                    }
                    switch ensureVisibleMode {
                    case .centerAggressive:
                        scrollToID(proxy, id: focusedRowID, extraDelay: 0.08)
                    case .bottomIfObscuredOnce:
                        ensureVisibleOnceBottom(proxy, id: focusedRowID)
                    case .none:
                        recomputeBottomLift()
                    }
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
    func recomputeBottomLift() {
        let margin: CGFloat = 16
        guard keyboardEndFrame.height > 0 else {
            withAnimation(.easeInOut(duration: 0.18)) { bottomLift = 0 }
            return
        }
        let keyboardTop = keyboardEndFrame.minY
        let overlap = focusedBottomY - (keyboardTop - margin)
        let needed = max(0, overlap)
        withAnimation(.easeInOut(duration: 0.18)) {
            bottomLift = min(needed, 260)
        }
    }

    func ensureVisibleOnceBottom(_ proxy: ScrollViewProxy, id: UUID?) {
        guard let id else { return }
        let now = Date()
        guard now.timeIntervalSince(lastEnsureAt) > 0.2 else { return }

        // 最小移動: 一度だけ .bottom へ寄せる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
            lastEnsureAt = Date()
        }
    }
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

// Preference key for broadcasting the focused row's global bottom Y
struct FocusedRowBottomPrefKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

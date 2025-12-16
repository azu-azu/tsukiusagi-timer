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
struct EditableModal<Content: View, BottomBar: View>: View {
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
    let bottomBar: (() -> BottomBar)?
    let hasBottomBar: Bool
    let isKeyboardCloseVisible: Bool
    let onKeyboardClose: () -> Void
    @Binding var focusedRowID: UUID?
    let ensureVisibleMode: EnsureVisibleMode

    @State private var lastEnsureAt: Date = .distantPast
    @State private var bottomLift: CGFloat = 0
    @State private var focusedBottomY: CGFloat = 0
    @State private var keyboardEndFrame: CGRect = .zero
    @State private var viewportHeight: CGFloat = 0
    @State private var pendingWork: DispatchWorkItem?
    private let descScrollSpace = "DescScroll"

    /// EditableModalの初期化
    /// - Parameters:
    ///   - title: モーダルのタイトル
    ///   - onSave: 保存ボタンタップ時のアクション
    ///   - onCancel: キャンセルボタンタップ時のアクション
    ///   - isKeyboardCloseVisible: キーボード閉じるボタンの表示状態
    ///   - onKeyboardClose: キーボード閉じるボタンタップ時のアクション
    ///   - bottomBar: オプショナルな下部入力バー（Reflection方式の入力）
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
        @ViewBuilder bottomBar: @escaping () -> BottomBar,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.onSave = onSave
        self.isSaveDisabled = isSaveDisabled
        self.onCancel = onCancel
        self.isKeyboardCloseVisible = isKeyboardCloseVisible
        self.onKeyboardClose = onKeyboardClose
        self.content = content
        self.bottomBar = bottomBar
        self.hasBottomBar = true
        self._focusedRowID = focusedRowID
        self.ensureVisibleMode = ensureVisibleMode
    }

    /// EditableModalの初期化（bottomBarなし - 後方互換性）
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
    ) where BottomBar == EmptyView {
        self.title = title
        self.onSave = onSave
        self.isSaveDisabled = isSaveDisabled
        self.onCancel = onCancel
        self.isKeyboardCloseVisible = isKeyboardCloseVisible
        self.onKeyboardClose = onKeyboardClose
        self.content = content
        self.bottomBar = nil
        self.hasBottomBar = false
        self._focusedRowID = focusedRowID
        self.ensureVisibleMode = ensureVisibleMode
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                content()
            }
            .padding()
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ViewportHeightPrefKey.self,
                        value: geo.frame(in: .named(descScrollSpace)).height
                    )
                }
            )
            // bottomBarがある場合、コンテンツ領域のタップでキーボードだけを閉じる（入力バーは残す）
            .contentShape(Rectangle())
            .onTapGesture {
                if hasBottomBar {
                    Keyboard.dismiss()
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                scrollContent
                .coordinateSpace(name: descScrollSpace)
                .scrollDismissesKeyboard(.interactively)
                // bottomBarがある場合はkeyboardAwareInsetを無効化（入力バーが余白を管理するため）
                .modifier(ConditionalKeyboardAwareInset(
                    isEnabled: !hasBottomBar,
                    baseBottomPadding: ensureVisibleMode == .none ? 0 : 16
                ))
                // bottomBarがある場合は外側タップで閉じる
                // Note: simultaneousGestureを削除し、contentのonTapGestureで処理する方が安全
                .onPreferenceChange(FocusedRowBottomPrefKey.self) { value in
                    focusedBottomY = value
                    recomputeBottomLift()
                }
                .onPreferenceChange(ViewportHeightPrefKey.self) { value in
                    viewportHeight = value
                    recomputeBottomLift()
                }
                .safeAreaInset(edge: .bottom) {
                    if let bottomBar {
                        bottomBar()
                    } else {
                        Color.clear.frame(height: bottomLift)
                    }
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
                        recomputeBottomLift(debounce: true)
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
                        recomputeBottomLift(debounce: true)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .disabled(isSaveDisabled)
                        .allowsHitTesting(!isSaveDisabled)
                }
                // bottomBarがある場合はキーボードツールバーを表示しない（入力バーが隠れるため）
                if !hasBottomBar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            onKeyboardClose()
                        } label: {
                            Label("Close", systemImage: "keyboard.chevron.compact.down")
                        }
                    }
                }
            }
            .keyboardCloseButton(
                isVisible: isKeyboardCloseVisible && !hasBottomBar,
                action: onKeyboardClose
            )
        }
        .background(DesignTokens.SkyToneColors.nightStart.ignoresSafeArea())
        .interactiveDismissDisabled() // 意図しない閉じ操作を防ぐ
    }
}

private extension EditableModal {
    func recomputeBottomLift(debounce: Bool = false) {
        let run = {
            let margin: CGFloat = 16
            guard keyboardEndFrame.height > 0 else {
                withAnimation(.easeInOut(duration: 0.18)) { bottomLift = 0 }
                return
            }
            let keyboardHeight = keyboardEndFrame.height
            let visibleBottom = max(0, viewportHeight - keyboardHeight - margin)
            let needed = max(0, focusedBottomY - visibleBottom)
            let clamped = min(needed, 280)
            let target = (abs(clamped - bottomLift) < 1) ? bottomLift : clamped
            withAnimation(.easeInOut(duration: 0.18)) { bottomLift = target }
        }

        if debounce {
            pendingWork?.cancel()
            let work = DispatchWorkItem(block: run)
            pendingWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: work)
        } else {
            run()
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

// Preference key for broadcasting the focused row's bottom Y in the named scroll coordinate space
struct FocusedRowBottomPrefKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// Preference key for the viewport height inside the named scroll coordinate space
struct ViewportHeightPrefKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// 条件付きでkeyboardAwareInsetを適用するモディファイア
private struct ConditionalKeyboardAwareInset: ViewModifier {
    let isEnabled: Bool
    let baseBottomPadding: CGFloat

    func body(content: Content) -> some View {
        if isEnabled {
            content.keyboardAwareInset(baseBottomPadding: baseBottomPadding)
        } else {
            content
        }
    }
}

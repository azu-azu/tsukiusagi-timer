import SwiftUI

// MARK: - 純粋なUI要素（適応型改良版）
struct KeyboardCloseButton: View {
    let action: () -> Void
    var isCompact: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(isCompact ? .caption : .body)
        }
        .foregroundColor(DesignTokens.MoonColors.textPrimary)
        .padding(isCompact ? 4 : 6)
        .background(
            Circle()
                .fill(Color.black.opacity(0.8))
        )
    }
}

// MARK: - 機能的な拡張（位置調整版）
extension View {
    /// キーボードクローズボタンを条件付きで表示（位置調整版）
    func adaptiveKeyboardCloseButton(
        isVisible: Bool,
        position: KeyboardCloseButtonPosition = .topTrailing,
        action: @escaping () -> Void
    ) -> some View {
        GeometryReader { geometry in
            ZStack {
                self
                if isVisible {
                    AdaptiveKeyboardCloseButtonOverlay(
                        geometry: geometry,
                        position: position,
                        action: action
                    )
                }
            }
        }
    }

    /// キーボードクローズボタンを条件付きで表示（レガシー版・カスタマイズ可能）
    func keyboardCloseButton(
        isVisible: Bool,
        isCompact: Bool = false,
        topPadding: CGFloat = 16,
        trailingPadding: CGFloat = 16,
        leadingPadding: CGFloat = 16,
        bottomPadding: CGFloat = 16,
        position: KeyboardCloseButtonPosition = .topTrailing,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            if isVisible {
                buttonPositionView(
                    position: position,
                    action: action,
                    isCompact: isCompact,
                    topPadding: topPadding,
                    trailingPadding: trailingPadding,
                    leadingPadding: leadingPadding,
                    bottomPadding: bottomPadding
                )
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }

    private func buttonPositionView(
        position: KeyboardCloseButtonPosition,
        action: @escaping () -> Void,
        isCompact: Bool,
        topPadding: CGFloat,
        trailingPadding: CGFloat,
        leadingPadding: CGFloat,
        bottomPadding: CGFloat
    ) -> some View {
        switch position {
        case .topTrailing:
            return AnyView(topTrailingButton(action: action, isCompact: isCompact,
                                           topPadding: topPadding, trailingPadding: trailingPadding))
        case .topLeading:
            return AnyView(topLeadingButton(action: action, isCompact: isCompact,
                                          topPadding: topPadding, leadingPadding: leadingPadding))
        case .bottomTrailing:
            return AnyView(bottomTrailingButton(action: action, isCompact: isCompact,
                                              bottomPadding: bottomPadding, trailingPadding: trailingPadding))
        case .bottomLeading:
            return AnyView(bottomLeadingButton(action: action, isCompact: isCompact,
                                             bottomPadding: bottomPadding, leadingPadding: leadingPadding))
        case .centerTrailing:
            return AnyView(centerTrailingButton(action: action, isCompact: isCompact,
                                              trailingPadding: trailingPadding))
        case .centerLeading:
            return AnyView(centerLeadingButton(action: action, isCompact: isCompact,
                                             leadingPadding: leadingPadding))
        }
    }

    private func topTrailingButton(action: @escaping () -> Void, isCompact: Bool,
                                 topPadding: CGFloat, trailingPadding: CGFloat) -> some View {
        VStack {
            HStack {
                Spacer()
                KeyboardCloseButton(action: action, isCompact: isCompact)
                    .padding(.trailing, trailingPadding)
                    .padding(.top, topPadding)
            }
            Spacer()
        }
    }

    private func topLeadingButton(action: @escaping () -> Void, isCompact: Bool,
                                topPadding: CGFloat, leadingPadding: CGFloat) -> some View {
        VStack {
            HStack {
                KeyboardCloseButton(action: action, isCompact: isCompact)
                    .padding(.leading, leadingPadding)
                    .padding(.top, topPadding)
                Spacer()
            }
            Spacer()
        }
    }

    private func bottomTrailingButton(action: @escaping () -> Void, isCompact: Bool,
                                    bottomPadding: CGFloat, trailingPadding: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                KeyboardCloseButton(action: action, isCompact: isCompact)
                    .padding(.trailing, trailingPadding)
                    .padding(.bottom, bottomPadding)
            }
        }
    }

    private func bottomLeadingButton(action: @escaping () -> Void, isCompact: Bool,
                                   bottomPadding: CGFloat, leadingPadding: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack {
                KeyboardCloseButton(action: action, isCompact: isCompact)
                    .padding(.leading, leadingPadding)
                    .padding(.bottom, bottomPadding)
                Spacer()
            }
        }
    }

    private func centerTrailingButton(action: @escaping () -> Void, isCompact: Bool,
                                    trailingPadding: CGFloat) -> some View {
        HStack {
            Spacer()
            KeyboardCloseButton(action: action, isCompact: isCompact)
                .padding(.trailing, trailingPadding)
        }
    }

    private func centerLeadingButton(action: @escaping () -> Void, isCompact: Bool,
                                   leadingPadding: CGFloat) -> some View {
        HStack {
            KeyboardCloseButton(action: action, isCompact: isCompact)
                .padding(.leading, leadingPadding)
            Spacer()
        }
    }
}

// MARK: - ボタン配置位置の定義
enum KeyboardCloseButtonPosition {
    case topTrailing
    case topLeading
    case bottomTrailing
    case bottomLeading
    case centerTrailing
    case centerLeading
}

// MARK: - 適応型オーバーレイコンポーネント（位置対応版）
struct AdaptiveKeyboardCloseButtonOverlay: View {
    let geometry: GeometryProxy
    let position: KeyboardCloseButtonPosition
    let action: () -> Void

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var keyboardHeight: CGFloat = 0

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }

    private var adjustedPadding: CGFloat {
        if isLandscape && isKeyboardVisible {
            return 8
        } else {
            return 16
        }
    }

    private var shouldUseCompactMode: Bool {
        if isLandscape && isKeyboardVisible {
            return true
        } else if isLandscape {
            return horizontalSizeClass == .compact
        }
        return false
    }

    var body: some View {
        buttonView
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            ) { notification in
                handleKeyboardShow(notification: notification)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in
                handleKeyboardHide()
            }
    }

    private func handleKeyboardShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = keyboardRectangle.height
            }
        }
    }

    private func handleKeyboardHide() {
        withAnimation(.easeInOut(duration: 0.3)) {
            keyboardHeight = 0
        }
    }

    @ViewBuilder
    private var buttonView: some View {
        switch position {
        case .topTrailing:
            topTrailingView
        case .topLeading:
            topLeadingView
        case .bottomTrailing:
            bottomTrailingView
        case .bottomLeading:
            bottomLeadingView
        case .centerTrailing:
            centerTrailingView
        case .centerLeading:
            centerLeadingView
        }
    }

    private var topTrailingView: some View {
        VStack {
            HStack {
                Spacer()
                KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                    .padding(.trailing, adjustedPadding)
                    .padding(.top, adjustedPadding)
            }
            Spacer()
        }
    }

    private var topLeadingView: some View {
        VStack {
            HStack {
                KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                    .padding(.leading, adjustedPadding)
                    .padding(.top, adjustedPadding)
                Spacer()
            }
            Spacer()
        }
    }

    private var bottomTrailingView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                    .padding(.trailing, adjustedPadding)
                    .padding(.bottom, adjustedPadding)
            }
        }
    }

    private var bottomLeadingView: some View {
        VStack {
            Spacer()
            HStack {
                KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                    .padding(.leading, adjustedPadding)
                    .padding(.bottom, adjustedPadding)
                Spacer()
            }
        }
    }

    private var centerTrailingView: some View {
        HStack {
            Spacer()
            KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                .padding(.trailing, adjustedPadding)
        }
    }

    private var centerLeadingView: some View {
        HStack {
            KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                .padding(.leading, adjustedPadding)
            Spacer()
        }
    }
}

// MARK: - KeyboardHelper（ヘルパー）
struct KeyboardHelper {
    static func hideKeyboard(completion: (() -> Void)? = nil) {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion?()
        }
    }
}

// MARK: - 使用例（位置指定版）
struct SafePositionExampleUsage: View {
    @FocusState private var isNameFocused: Bool
    @FocusState private var isSubtitleFocused: Bool
    @State private var name: String = ""
    @State private var subtitle: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Subtitle", text: $subtitle)
                    .focused($isSubtitleFocused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Spacer()
            }
            .padding()
            .adaptiveKeyboardCloseButton(
                isVisible: isNameFocused || isSubtitleFocused,
                position: .topLeading,
                action: {
                    KeyboardHelper.hideKeyboard {
                        isNameFocused = false
                        isSubtitleFocused = false
                    }
                }
            )
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save処理
                    }
                    .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
            }
        }
    }
}

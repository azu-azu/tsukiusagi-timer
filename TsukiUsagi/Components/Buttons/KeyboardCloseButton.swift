import SwiftUI

// MARK: - 純粋なUI要素（適応型改良版）
struct KeyboardCloseButton: View {
    let action: () -> Void
    var isCompact: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(isCompact ? .caption : .body) // より小さなサイズに調整
        }
        .foregroundColor(DesignTokens.Colors.moonTextPrimary)
        .padding(isCompact ? 4 : 6) // より小さなパディング
        .background(
            Circle()
                .fill(Color.black.opacity(0.8))
        )
    }
}

// MARK: - 機能的な拡張（位置調整版）
extension View {
    /// キーボードクローズボタンを条件付きで表示（位置調整版）
    ///
    /// - Note: Saveボタンなどの右上要素と重ならないよう、位置を調整可能
    ///
    /// - Parameters:
    ///   - isVisible: ボタンの表示状態
    ///   - position: ボタンの配置位置
    ///   - action: ボタンタップ時のアクション
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
    ///
    /// - Note: このmodifierは対象Viewの指定位置にボタンを配置します
    ///
    /// - Parameters:
    ///   - isVisible: ボタンの表示状態
    ///   - isCompact: コンパクト表示するかどうか
    ///   - topPadding: 上部からのパディング（デフォルト16）
    ///   - trailingPadding: 右端からのパディング（デフォルト16）
    ///   - leadingPadding: 左端からのパディング（左配置時のみ）
    ///   - bottomPadding: 下部からのパディング（下配置時のみ）
    ///   - position: ボタンの配置位置
    ///   - action: ボタンタップ時のアクション
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
                switch position {
                case .topTrailing:
                    VStack {
                        HStack {
                            Spacer()
                            KeyboardCloseButton(action: action, isCompact: isCompact)
                                .padding(.trailing, trailingPadding)
                                .padding(.top, topPadding)
                        }
                        Spacer()
                    }
                case .topLeading:
                    VStack {
                        HStack {
                            KeyboardCloseButton(action: action, isCompact: isCompact)
                                .padding(.leading, leadingPadding)
                                .padding(.top, topPadding)
                            Spacer()
                        }
                        Spacer()
                    }
                case .bottomTrailing:
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            KeyboardCloseButton(action: action, isCompact: isCompact)
                                .padding(.trailing, trailingPadding)
                                .padding(.bottom, bottomPadding)
                        }
                    }
                case .bottomLeading:
                    VStack {
                        Spacer()
                        HStack {
                            KeyboardCloseButton(action: action, isCompact: isCompact)
                                .padding(.leading, leadingPadding)
                                .padding(.bottom, bottomPadding)
                            Spacer()
                        }
                    }
                case .centerTrailing:
                    HStack {
                        Spacer()
                        KeyboardCloseButton(action: action, isCompact: isCompact)
                            .padding(.trailing, trailingPadding)
                    }
                case .centerLeading:
                    HStack {
                        KeyboardCloseButton(action: action, isCompact: isCompact)
                            .padding(.leading, leadingPadding)
                        Spacer()
                    }
                }
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}

// MARK: - ボタン配置位置の定義
enum KeyboardCloseButtonPosition {
    case topTrailing      // 右上（デフォルト）
    case topLeading       // 左上（Saveボタンと重ならない）
    case bottomTrailing   // 右下
    case bottomLeading    // 左下
    case centerTrailing   // 右中央
    case centerLeading    // 左中央
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

    private var availableHeight: CGFloat {
        geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
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
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                    as? NSValue
                {
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    withAnimation(.easeInOut(duration: 0.3)) {
                        keyboardHeight = keyboardRectangle.height
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
    }

    @ViewBuilder
    private var buttonView: some View {
        switch position {
        case .topTrailing:
            VStack {
                HStack {
                    Spacer()
                    KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                        .padding(.trailing, adjustedPadding)
                        .padding(.top, adjustedPadding)
                }
                Spacer()
            }
        case .topLeading:
            VStack {
                HStack {
                    KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                        .padding(.leading, adjustedPadding)
                        .padding(.top, adjustedPadding)
                    Spacer()
                }
                Spacer()
            }
        case .bottomTrailing:
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                        .padding(.trailing, adjustedPadding)
                        .padding(.bottom, adjustedPadding)
                }
            }
        case .bottomLeading:
            VStack {
                Spacer()
                HStack {
                    KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                        .padding(.leading, adjustedPadding)
                        .padding(.bottom, adjustedPadding)
                    Spacer()
                }
            }
        case .centerTrailing:
            HStack {
                Spacer()
                KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                    .padding(.trailing, adjustedPadding)
            }
        case .centerLeading:
            HStack {
                KeyboardCloseButton(action: action, isCompact: shouldUseCompactMode)
                    .padding(.leading, adjustedPadding)
                Spacer()
            }
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

        // 少し遅延してからコールバック実行
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
                position: .topLeading, // 左上に配置してSaveボタンと重ならない
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
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - 設計方針
/*
✅ 位置選択可能：
  - .topLeading: Saveボタンと重ならない左上
  - .bottomTrailing: 右下（キーボードから離れた位置）
  - .centerLeading: 左中央（視認性と操作性のバランス）
  - その他の位置も選択可能

✅ 推奨配置：
  - 右上にSaveボタンがある場合: .topLeading
  - 右下にボタンがある場合: .topTrailing
  - 画面が狭い場合: .centerLeading

✅ 適応性：
  - 横向き時は自動的にコンパクト表示
  - キーボード表示時は位置とサイズを自動調整
  - 利用可能スペースに基づく最適化

使用例:
.adaptiveKeyboardCloseButton(
    isVisible: keyboardIsVisible,
    position: .topLeading, // Saveボタンと重ならない
    action: { hideKeyboard() }
)
*/

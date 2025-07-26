import SwiftUI

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
        .background(Circle().fill(Color.black.opacity(0.8)))
    }
}

extension View {
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
        let config = ButtonConfig(
            isCompact: isCompact,
            topPadding: topPadding,
            trailingPadding: trailingPadding,
            leadingPadding: leadingPadding,
            bottomPadding: bottomPadding
        )

        return ZStack {
            self
            if isVisible {
                buttonPositionView(position: position, action: action, config: config)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }

    private func buttonPositionView(
        position: KeyboardCloseButtonPosition,
        action: @escaping () -> Void,
        config: ButtonConfig
    ) -> some View {
        switch position {
        case .topTrailing:
            return AnyView(topTrailingButton(action: action, config: config))
        case .topLeading:
            return AnyView(topLeadingButton(action: action, config: config))
        case .bottomTrailing:
            return AnyView(bottomTrailingButton(action: action, config: config))
        case .bottomLeading:
            return AnyView(bottomLeadingButton(action: action, config: config))
        case .centerTrailing:
            return AnyView(centerTrailingButton(action: action, config: config))
        case .centerLeading:
            return AnyView(centerLeadingButton(action: action, config: config))
        }
    }

    private func topTrailingButton(action: @escaping () -> Void, config: ButtonConfig) -> some View {
        VStack {
            HStack {
                Spacer()
                KeyboardCloseButton(action: action, isCompact: config.isCompact)
                    .padding(.trailing, config.trailingPadding)
                    .padding(.top, config.topPadding)
            }
            Spacer()
        }
    }

    private func topLeadingButton(action: @escaping () -> Void, config: ButtonConfig) -> some View {
        VStack {
            HStack {
                KeyboardCloseButton(action: action, isCompact: config.isCompact)
                    .padding(.leading, config.leadingPadding)
                    .padding(.top, config.topPadding)
                Spacer()
            }
            Spacer()
        }
    }

    private func bottomTrailingButton(action: @escaping () -> Void, config: ButtonConfig) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                KeyboardCloseButton(action: action, isCompact: config.isCompact)
                    .padding(.trailing, config.trailingPadding)
                    .padding(.bottom, config.bottomPadding)
            }
        }
    }

    private func bottomLeadingButton(action: @escaping () -> Void, config: ButtonConfig) -> some View {
        VStack {
            Spacer()
            HStack {
                KeyboardCloseButton(action: action, isCompact: config.isCompact)
                    .padding(.leading, config.leadingPadding)
                    .padding(.bottom, config.bottomPadding)
                Spacer()
            }
        }
    }

    private func centerTrailingButton(action: @escaping () -> Void, config: ButtonConfig) -> some View {
        HStack {
            Spacer()
            KeyboardCloseButton(action: action, isCompact: config.isCompact)
                .padding(.trailing, config.trailingPadding)
        }
    }

    private func centerLeadingButton(action: @escaping () -> Void, config: ButtonConfig) -> some View {
        HStack {
            KeyboardCloseButton(action: action, isCompact: config.isCompact)
                .padding(.leading, config.leadingPadding)
            Spacer()
        }
    }
}
}

struct ButtonConfig {
    let isCompact: Bool
    let topPadding: CGFloat
    let trailingPadding: CGFloat
    let leadingPadding: CGFloat
    let bottomPadding: CGFloat
}

enum KeyboardCloseButtonPosition {
    case topTrailing, topLeading, bottomTrailing, bottomLeading, centerTrailing, centerLeading
}

struct AdaptiveKeyboardCloseButtonOverlay: View {
    let geometry: GeometryProxy
    let position: KeyboardCloseButtonPosition
    let action: () -> Void

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var keyboardHeight: CGFloat = 0

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var isKeyboardVisible: Bool { keyboardHeight > 0 }
    private var adjustedPadding: CGFloat { isLandscape && isKeyboardVisible ? 8 : 16 }
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
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) {
                handleKeyboardShow(notification: $0)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
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

struct KeyboardHelper {
    static func hideKeyboard(completion: (() -> Void)? = nil) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { completion?() }
    }
}

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
                    Button("Save") { }
                        .foregroundColor(DesignTokens.MoonColors.accentBlue)
                }
            }
        }
    }
}

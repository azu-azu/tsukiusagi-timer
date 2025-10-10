import SwiftUI
import Combine

// MARK: - Keyboard Helper

enum Keyboard {
    /// Dismisses the keyboard by resigning the current first responder.
    @MainActor static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Modifiers

public struct DismissKeyboardOnTap: ViewModifier {
    let onDismiss: () -> Void

    public func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                onDismiss()
                Task { @MainActor in
                    Keyboard.dismiss()
                }
            }
    }
}

private final class KeyboardHeightObserver: ObservableObject {
    @Published var height: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        let changePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification -> CGFloat? in
                guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                    return nil
                }
                let endFrame = value.cgRectValue
                let screenHeight = UIScreen.main.bounds.height
                let height = max(0, screenHeight - endFrame.origin.y)
                return height.isFinite ? height : 0
            }

        let hidePublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        changePublisher
            .merge(with: hidePublisher)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] newHeight in
                self?.height = newHeight
            }
            .store(in: &cancellables)
    }
}

private struct KeyboardAwareInset: ViewModifier {
    @StateObject private var observer = KeyboardHeightObserver()
    let baseBottomPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: insetHeight)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.25), value: insetHeight)
            }
    }

    private var insetHeight: CGFloat {
        max(0, observer.height - baseBottomPadding)
    }
}

private struct KeyboardAwareBottomPadding: ViewModifier {
    @StateObject private var observer = KeyboardHeightObserver()
    let baseBottomPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.bottom, paddingAmount)
    }

    private var paddingAmount: CGFloat {
        max(0, observer.height - baseBottomPadding)
    }
}

enum KeyboardCloseLabelStyle {
    case iconOnly
    case iconWithText(String)
}

public struct KeyboardCloseToolbar: ViewModifier {
    let labelStyle: KeyboardCloseLabelStyle
    let onClose: () -> Void

    public func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: onClose) {
                    label
                }
                .accessibilityIdentifier("KeyboardToolbarCloseButton")
                .accessibilityLabel(accessibilityLabel)
            }
        }
    }

    @ViewBuilder
    private var label: some View {
        switch labelStyle {
        case .iconOnly:
            Image(systemName: "keyboard.chevron.compact.down")
        case .iconWithText(let text):
            Label(text, systemImage: "keyboard.chevron.compact.down")
        }
    }

    private var accessibilityLabel: String {
        switch labelStyle {
        case .iconOnly:
            return "Close Keyboard"
        case .iconWithText(let text):
            return text
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds a tap gesture that clears focus using the provided closure before dismissing the keyboard.
    func dismissKeyboardOnTap(_ onDismiss: @escaping () -> Void) -> some View {
        modifier(DismissKeyboardOnTap(onDismiss: onDismiss))
    }

    /// Adds a safe-area inset that matches the current keyboard height.
    func keyboardAwareInset(baseBottomPadding: CGFloat = 0) -> some View {
        modifier(KeyboardAwareInset(baseBottomPadding: baseBottomPadding))
    }

    /// Adds bottom padding that grows with the keyboard height, minus any fixed baseline padding already present.
    func keyboardAwareBottomPadding(baseBottomPadding: CGFloat = 0) -> some View {
        modifier(KeyboardAwareBottomPadding(baseBottomPadding: baseBottomPadding))
    }

    /// Adds a keyboard toolbar close button that uses the standard keyboard icon.
    func keyboardCloseToolbar(labelStyle: KeyboardCloseLabelStyle = .iconOnly,
                              onClose: @escaping () -> Void) -> some View {
        modifier(KeyboardCloseToolbar(labelStyle: labelStyle, onClose: onClose))
    }
}

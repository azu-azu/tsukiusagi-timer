import SwiftUI

public struct HiddenKeyboardWarmer: View {
    @FocusState private var isFocused: Bool

    public init() {}

    public var body: some View {
        TextField("", text: .constant(""))
            .opacity(0.01)
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .focused($isFocused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = false
                    }
                }
            }
    }
}

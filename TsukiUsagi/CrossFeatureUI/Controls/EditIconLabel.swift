import SwiftUI

struct EditIconLabel: View {
    let text: String

    init(text: String = Copy.Button.edit) {
        self.text = text
    }

    var body: some View {
        Label(text, systemImage: "pencil")
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(DesignTokens.IconColors.pencil)
            .accessibilityLabel(text)
    }
}

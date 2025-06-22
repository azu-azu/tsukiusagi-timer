import SwiftUI

struct SelectableTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.widthTracksTextView = true
        tv.textContainer.lineBreakMode = .byWordWrapping
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let attrString = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: textColor
            ]
        )
        uiView.attributedText = attrString
    }
}
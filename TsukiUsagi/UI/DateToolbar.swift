import SwiftUI

struct DateToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Text(AppFormatters.displayDate.string(from: Date()))
                        .titleWhite(size: 16, weight: .regular, design: .monospaced)

                    // 右端に余白（または他のアイテム）
                    Spacer()
                }
            }
    }
}

/// “甘い”エクステンション
extension View {
    /// ナビバー左端に日付を出す
    func dateToolbar() -> some View {
        modifier(DateToolbar())
    }
}

import SwiftUI

/// 日付用フォーマッタ（再利用）
private let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-M-d EEE"
    f.locale = Locale(identifier: "en_US")
    return f
}()

struct DateToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Text(dateFormatter.string(from: Date()))
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


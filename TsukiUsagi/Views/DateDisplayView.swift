import SwiftUI

struct DateDisplayView: View {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d EEE."
        formatter.locale = Locale(identifier: "en_US")
        // formatter.locale = Locale(identifier: "ja_JP") // 日本語の曜日
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateDisplayView.dateFormatter.string(from: Date()))
                .titleWhiteBold(size: 16)
        }
        .foregroundColor(.white)
        .offset(x: 10, y: 2) // 位置を調整
    }
}

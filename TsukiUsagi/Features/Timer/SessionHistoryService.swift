import Foundation

protocol SessionHistoryServiceable: AnyObject {
    func add(parameters: AddSessionParameters)
}

final class SessionHistoryService: SessionHistoryServiceable {
    private let formatter: TimeFormatterUtilable
    // HistoryViewModel等もここで保持

    init(formatter: TimeFormatterUtilable) {
        self.formatter = formatter
    }

    func add(parameters: AddSessionParameters) {
        // 履歴保存ロジック
        // formatterを使って表示用テキスト生成も可能
    }
}

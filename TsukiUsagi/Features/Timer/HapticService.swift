import Foundation

protocol HapticServiceable: AnyObject {
    func heavyImpact()
    func lightImpact()
}

final class HapticService: HapticServiceable {
    func heavyImpact() {
        // HapticManager呼び出し
    }
    func lightImpact() {
        // HapticManager呼び出し
    }
}

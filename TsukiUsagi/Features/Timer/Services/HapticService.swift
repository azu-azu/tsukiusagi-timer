import Foundation

protocol HapticServiceable: AnyObject {
    func heavyImpact()
    func lightImpact()
}

final class HapticService: HapticServiceable {
    func heavyImpact() {
        HapticManager.shared.heavyImpact()
    }

    func lightImpact() {
        HapticManager.shared.lightImpact()
    }
}

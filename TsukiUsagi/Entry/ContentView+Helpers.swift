import SwiftUI

extension ContentView {
    // MARK: - Layout Calculations

    /// より正確な向き判定（iPad Split View対応）
    func safeIsLandscape(size: CGSize, horizontalClass: UserInterfaceSizeClass?) -> Bool {
        guard size.width > 0, size.height > 0 else { return false }
        return horizontalClass == .regular ||
            (size.width > size.height && size.width > 600)
    }

    /// デバイス別のマージン調整
    func landscapeMargin() -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 40 // iPad は余裕を持たせる
        } else {
            return 20 // iPhone はコンパクトに
        }
    }

    /// 星アニメ可否の単一の真理
    func shouldAnimateStars(
        reduceMotion: Bool,
        showingSideMenu: Bool,
        timeRemaining: Int,
        workLengthMinutes: Int,
        isRunning: Bool
    ) -> Bool {
        if reduceMotion { return false }
        if showingSideMenu { return false }
        let isInitial = timeRemaining == workLengthMinutes * 60
        return isRunning || isInitial
    }

}

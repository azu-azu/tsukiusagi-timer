import SwiftUI

// MARK: - Dynamic Debug ViewModifiers

/// 動的更新対応の画面レベルデバッグModifier
///
/// 責務:
/// - UserDefaults変更の即座反映
/// - NotificationCenterとの連携
/// - リアルタイム表示切り替え
struct DynamicDebugScreenModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
    }

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

/// 動的更新対応のセクションレベルデバッグModifier
struct DynamicDebugSectionModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
    }

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

/// 動的更新対応のコンポーネントレベルデバッグModifier
struct DynamicDebugComponentModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
    }

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

/// 動的更新対応のフォームレベルデバッグModifier
struct DynamicDebugFormModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
    }

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

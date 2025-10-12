import SwiftUI

// MARK: - Core Debug ViewModifier

/// 基本的なデバッグ表示用ViewModifier
///
/// 責務:
/// - モジュール名の表示
/// - アクセシビリティID設定
/// - DEBUG条件付きコンパイル
struct DebugModuleNameModifier: ViewModifier {
    let moduleName: String
    let position: Alignment
    let isVisible: Bool

    init(
        _ moduleName: String,
        position: Alignment = .topTrailing,
        isVisible: Bool = true
    ) {
        self.moduleName = moduleName
        self.position = position
        self.isVisible = isVisible
    }

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}


// MARK: - View Extension (Basic)

extension View {
    /// デバッグモードでモジュール名を表示
    func debugModuleName(
        _ name: String,
        position: Alignment = .topTrailing,
        isVisible: Bool = true
    ) -> some View {
        self.modifier(
            DebugModuleNameModifier(
                name,
                position: position,
                isVisible: isVisible
            )
        )
    }

    /// シンプルなデバッグ表示（ふじこ式）
    func debug(_ name: String, position: Alignment = .topTrailing) -> some View {
        self.debugModuleName(name, position: position, isVisible: true)
    }
}

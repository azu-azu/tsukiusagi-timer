import SwiftUI

// MARK: - Hierarchical Debug ViewModifiers

/// 画面レベルのデバッグViewModifier（青色）
///
/// 責務:
/// - 画面全体の識別表示
/// - AppStorageとの連携
/// - 動的な表示切り替え
struct DebugScreenModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

/// セクションレベルのデバッグViewModifier（緑色）
///
/// 責務:
/// - セクション単位の識別表示
/// - 中間レベルの構造把握
struct DebugSectionModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

/// コンポーネントレベルのデバッグViewModifier（赤色）
///
/// 責務:
/// - 個別コンポーネントの識別表示
/// - 詳細レベルの構造把握
struct DebugComponentModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

/// フォームレベルのデバッグViewModifier（オレンジ色）
///
/// 責務:
/// - フォームやUI入力要素の識別表示
/// - ユーザーインタラクション要素の把握
struct DebugFormModifier: ViewModifier {
    let moduleName: String
    let position: Alignment

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
    }
}

// MARK: - View Extension (Hierarchical)

extension View {
    /// 画面レベルのデバッグ表示（青）
    func debugScreen(_ name: String, position: Alignment = .top) -> some View {
        self.modifier(DebugScreenModifier(moduleName: name, position: position))
    }

    /// セクションレベルのデバッグ表示（緑）
    func debugSection(_ name: String, position: Alignment = .top) -> some View {
        self.modifier(DebugSectionModifier(moduleName: name, position: position))
    }

    /// コンポーネントレベルのデバッグ表示（赤）
    func debugComponent(_ name: String, position: Alignment = .top) -> some View {
        self.modifier(DebugComponentModifier(moduleName: name, position: position))
    }

    /// フォームレベルのデバッグ表示（オレンジ）
    func debugForm(_ name: String, position: Alignment = .top) -> some View {
        self.modifier(DebugFormModifier(moduleName: name, position: position))
    }
}

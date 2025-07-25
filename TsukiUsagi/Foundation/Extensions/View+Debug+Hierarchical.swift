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
    @AppStorage("DebugShowModuleNames") private var showModuleNames: Bool = true

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
            #if DEBUG
            .overlay(
                Group {
                    if showModuleNames {
                        Text(moduleName)
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.8))
                            )
                    }
                },
                alignment: position
            )
            #endif
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
    @AppStorage("DebugShowModuleNames") private var showModuleNames: Bool = true

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
            #if DEBUG
            .overlay(
                Group {
                    if showModuleNames {
                        Text(moduleName)
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green.opacity(0.8))
                            )
                    }
                },
                alignment: position
            )
            #endif
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
    @AppStorage("DebugShowModuleNames") private var showModuleNames: Bool = true

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
            #if DEBUG
            .overlay(
                Group {
                    if showModuleNames {
                        Text(moduleName)
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.8))
                            )
                    }
                },
                alignment: position
            )
            #endif
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
    @AppStorage("DebugShowModuleNames") private var showModuleNames: Bool = true

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(moduleName)
            #if DEBUG
            .overlay(
                Group {
                    if showModuleNames {
                        Text(moduleName)
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange.opacity(0.8))
                            )
                    }
                },
                alignment: position
            )
            #endif
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

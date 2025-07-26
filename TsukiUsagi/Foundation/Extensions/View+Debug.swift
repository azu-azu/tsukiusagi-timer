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
            #if DEBUG
            .overlay(
                Group {
                    if isVisible {
                        Text(moduleName)
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignTokens.MoonColors.errorBackground)
                            )
                    }
                },
                alignment: position
            )
            #endif
    }
}

// MARK: - Debug Settings

/// デバッグ設定の管理
///
/// 責務:
/// - デバッグ表示の有効/無効制御
/// - UserDefaultsとの連携
/// - 設定の切り替え機能
struct DebugSettings {
    static var showModuleNames: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "DebugShowModuleNames")
        #else
        return false
        #endif
    }

    static func toggleModuleNames() {
        #if DEBUG
        UserDefaults.standard.set(!showModuleNames, forKey: "DebugShowModuleNames")
        #endif
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
        self.debugModuleName(name, position: position, isVisible: DebugSettings.showModuleNames)
    }
}

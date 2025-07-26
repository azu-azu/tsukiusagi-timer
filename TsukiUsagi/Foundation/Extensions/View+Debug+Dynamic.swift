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
    @State private var isVisible: Bool = DebugSettings.showModuleNames

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
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
                                    .fill(Color.blue.opacity(0.8))
                            )
                    }
                },
                alignment: position
            )
            #endif
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                isVisible = DebugSettings.showModuleNames
            }
    }
}

/// 動的更新対応のセクションレベルデバッグModifier
struct DynamicDebugSectionModifier: ViewModifier {
    let moduleName: String
    let position: Alignment
    @State private var isVisible: Bool = DebugSettings.showModuleNames

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
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
                                    .fill(Color.green.opacity(0.8))
                            )
                    }
                },
                alignment: position
            )
            #endif
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                isVisible = DebugSettings.showModuleNames
            }
    }
}

/// 動的更新対応のコンポーネントレベルデバッグModifier
struct DynamicDebugComponentModifier: ViewModifier {
    let moduleName: String
    let position: Alignment
    @State private var isVisible: Bool = DebugSettings.showModuleNames

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
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
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                isVisible = DebugSettings.showModuleNames
            }
    }
}

/// 動的更新対応のフォームレベルデバッグModifier
struct DynamicDebugFormModifier: ViewModifier {
    let moduleName: String
    let position: Alignment
    @State private var isVisible: Bool = DebugSettings.showModuleNames

    init(_ moduleName: String, position: Alignment = .topTrailing) {
        self.moduleName = moduleName
        self.position = position
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
                                    .fill(Color.orange.opacity(0.8))
                            )
                    }
                },
                alignment: position
            )
            #endif
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                isVisible = DebugSettings.showModuleNames
            }
    }
}

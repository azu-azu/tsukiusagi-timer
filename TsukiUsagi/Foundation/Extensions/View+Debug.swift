import SwiftUI

// MARK: - Debug ViewModifier
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
                            .font(.system(size: 8, weight: .bold))
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

// MARK: - 階層別デバッグViewModifier
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
                            .font(.system(size: 8, weight: .bold))
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
                            .font(.system(size: 8, weight: .bold))
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
                            .font(.system(size: 8, weight: .bold))
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
                            .font(.system(size: 8, weight: .bold))
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

// MARK: - View Extension
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

// MARK: - Debug Settings
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

// MARK: - 動的デバッグViewModifier
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
                            .font(.system(size: 8, weight: .bold))
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
                            .font(.system(size: 8, weight: .bold))
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
                            .font(.system(size: 8, weight: .bold))
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
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                isVisible = DebugSettings.showModuleNames
            }
    }
}

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
                            .font(.system(size: 8, weight: .bold))
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

// MARK: - 使用例とベストプラクティス
/*
// 1. 基本的な使用（ふじこ式）
struct SessionLabelSection: View {
    var body: some View {
        VStack {
            // コンテンツ
        }
        .debug("SessionLabelSection")
    }
}

// 2. 階層別の使用
struct SettingsView: View {
    var body: some View {
        VStack {
            WorkTimeSectionView()
                .debugSection("WorkTimeSectionView", position: .topLeading)

            BreakTimeSectionView()
                .debugSection("BreakTimeSectionView", position: .topLeading)
        }
        .debugScreen("SettingsView")
    }
}

// 3. コンポーネントレベル
struct TimerPanel: View {
    var body: some View {
        VStack {
            // コンテンツ
        }
        .debugComponent("TimerPanel", position: .topLeading)
    }
}

// 4. フォームレベル
struct NewSessionFormView: View {
    var body: some View {
        VStack {
            // コンテンツ
        }
        .debugForm("NewSessionFormView")
    }
}

// 5. 従来の方法（後方互換性）
struct SomeView: View {
    var body: some View {
        VStack {
            // コンテンツ
        }
        .debugModuleName(
            "SomeView",
            isVisible: DebugSettings.showModuleNames
        )
    }
}
*/

// MARK: - デバッグメニュー（設定画面などで使用）
struct DebugMenuView: View {
    @AppStorage("DebugShowModuleNames") private var showModuleNames: Bool = true

    var body: some View {
        #if DEBUG
        Section("Debug Options") {
            Toggle("Show Module Names", isOn: $showModuleNames)
        }
        #endif
    }
}

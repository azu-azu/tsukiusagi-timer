import SwiftUI

// MARK: - Debug Menu Component

/// デバッグ機能の設定UI
///
/// 責務:
/// - デバッグ表示のON/OFF切り替え
/// - 設定画面への組み込み
/// - ユーザー向けデバッグメニュー提供
struct DebugMenuView: View {
    @AppStorage("DebugShowModuleNames") private var showModuleNames: Bool = true

    var body: some View {
        #if DEBUG
        Section {
            Toggle("Show Module Names", isOn: $showModuleNames)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
        } header: {
            Text("Debug Options")
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
        }
        #endif
    }
}

// MARK: - Usage Examples & Best Practices

/*
使用例とベストプラクティス

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

// 6. 動的デバッグ（リアルタイム更新が必要な場合）
struct DynamicView: View {
    var body: some View {
        VStack {
            // コンテンツ
        }
        .modifier(DynamicDebugScreenModifier("DynamicView"))
    }
}

// 7. 設定画面への組み込み
struct SettingsView: View {
    var body: some View {
        Form {
            // 他の設定項目

            DebugMenuView()
        }
    }
}

// 8. カラーコード一覧
// - 青色(.blue): 画面レベル (debugScreen)
// - 緑色(.green): セクションレベル (debugSection)
// - 赤色(.red): コンポーネントレベル (debugComponent)
// - オレンジ色(.orange): フォームレベル (debugForm)

// 9. ポジション指定例
struct ExampleView: View {
    var body: some View {
        VStack {
            // コンテンツ
        }
        .debugScreen("ExampleView", position: .topLeading)    // 左上
        .debugSection("Section", position: .topTrailing)     // 右上
        .debugComponent("Component", position: .bottomLeading) // 左下
        .debugForm("Form", position: .bottomTrailing)        // 右下
    }
}

// 10. 条件付き表示
struct ConditionalDebugView: View {
    let showDebug: Bool

    var body: some View {
        VStack {
            // コンテンツ
        }
        .debugModuleName("ConditionalDebugView", isVisible: showDebug)
    }
}
*/

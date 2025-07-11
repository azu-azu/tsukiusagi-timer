import Foundation

/// Feature Flag の管理
/// リリース時の安全性を保証するため、明示的な初期値設定を行う
enum FeatureFlags {
    // MARK: - Keys

    private enum Keys {
        /// 統一UI の有効/無効
        static let unifiedUI = "enableUnifiedUI"
    }

    // MARK: - Unified UI

    /// 統一UI の有効/無効
    /// リリース時は false をデフォルトとする
    static var enableUnifiedUI: Bool {
        get {
            // 明示的にデフォルト値を false に設定
            // UserDefaults.bool(forKey:) は値が存在しない場合 false を返すが、
            // 明示的に nil チェックを行うことで安全性を保証
            if UserDefaults.standard.object(forKey: Keys.unifiedUI) == nil {
                return false // デフォルト値
            }
            return UserDefaults.standard.bool(forKey: Keys.unifiedUI)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.unifiedUI)
        }
    }

    // MARK: - Initialization

    /// アプリ起動時にデフォルト値を設定
    /// リリースビルド時は false を設定
    static func setDefaultValues() {
        // 既存の値が設定されていない場合のみデフォルト値を設定
        if UserDefaults.standard.object(forKey: Keys.unifiedUI) == nil {
            #if DEBUG
                // デバッグビルド時は開発の利便性のため true に設定
                UserDefaults.standard.set(true, forKey: Keys.unifiedUI)
            #else
                // リリースビルド時は安全性のため false に設定
                UserDefaults.standard.set(false, forKey: Keys.unifiedUI)
            #endif
        }
    }

    // MARK: - Reset

    /// 開発用：Feature Flag をリセット
    /// デバッグ時のみ使用
    static func resetToDefaults() {
        #if DEBUG
            UserDefaults.standard.removeObject(forKey: Keys.unifiedUI)
            setDefaultValues()
        #endif
    }

    // MARK: - Debug Info

    /// デバッグ用：現在の設定を表示
    static func debugInfo() -> String {
        #if DEBUG
            return """
            Feature Flags Debug Info:
            - enableUnifiedUI: \(enableUnifiedUI)
            - Keys.unifiedUI: \(Keys.unifiedUI)
            """
        #else
            return "Feature Flags Debug Info: Not available in release build"
        #endif
    }
}

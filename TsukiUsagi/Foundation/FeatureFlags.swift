import Foundation

/// Feature Flag の管理
/// リリース時の安全性を保証するため、明示的な初期値設定を行う
enum FeatureFlags {
    // MARK: - Keys

    private enum Keys {
        /// 統一UI の有効/無効
        static let unifiedUI = "enableUnifiedUI"

        /// Streak機能のフラグ
        static let achievements = "enableAchievements"
        static let xp = "enableXP"
        static let sharing = "enableSharing"
        static let smartNotifications = "enableSmartNotifications"
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

    // historyInlineReflection removed: daily reflection is always enabled

    // MARK: - Streak Features

    /// アチーブメント機能の有効/無効
    /// MVPでは false をデフォルトとする
    static var achievements: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.achievements) == nil {
                return false // MVP: デフォルト値
            }
            return UserDefaults.standard.bool(forKey: Keys.achievements)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.achievements)
        }
    }

    /// XP機能の有効/無効
    /// MVPでは false をデフォルトとする
    static var xp: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.xp) == nil {
                return false // MVP: デフォルト値
            }
            return UserDefaults.standard.bool(forKey: Keys.xp)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.xp)
        }
    }

    /// シェア機能の有効/無効
    /// MVPでは false をデフォルトとする
    static var sharing: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.sharing) == nil {
                return false // MVP: デフォルト値
            }
            return UserDefaults.standard.bool(forKey: Keys.sharing)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.sharing)
        }
    }

    /// スマート通知機能の有効/無効
    /// MVPでは false をデフォルトとする
    static var smartNotifications: Bool {
        get {
            if UserDefaults.standard.object(forKey: Keys.smartNotifications) == nil {
                return false // MVP: デフォルト値
            }
            return UserDefaults.standard.bool(forKey: Keys.smartNotifications)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.smartNotifications)
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

        // historyInlineReflection removed

        // Streak機能のデフォルト値設定（MVPでは全て false）
        let streakKeys = [Keys.achievements, Keys.xp, Keys.sharing, Keys.smartNotifications]
        for key in streakKeys where UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(false, forKey: key) // MVP: 全て無効
        }
    }
}

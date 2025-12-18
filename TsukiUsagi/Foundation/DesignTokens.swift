import SwiftUI
/// デザイン定数の一元管理
/// Asset Catalog からカラーを参照し、Light/Dark モードに対応
enum DesignTokens {
    // MARK: - Colors (意味別グルーピング)
    enum UtilityColors {
        /// 重複警告用の視認性高いアクセントカラー
        static let duplicateWarning = SwiftUI.Color(red: 0.90, green: 0.38, blue: 0.00)
        static let gray = SwiftUI.Color.gray
        static let green = SwiftUI.Color.green
        static let yellow = SwiftUI.Color.yellow
        static let orange = SwiftUI.Color.orange
    }
    /// 月の光をテーマにしたテキストカラー
    enum MoonColors {
        /// プライマリテキスト色（Light/Dark モード対応）
        /// 優しい白
        static let textPrimary = Color("moonTextPrimary")
        /// セカンダリテキスト色（Light/Dark モード対応）
        /// primaryよりも薄い白
        static let textSecondary = Color("moonTextSecondary")
        /// ミュートテキスト色（Light/Dark モード対応）
        /// Color.white.opacity(0.45) // Dark mode
        /// Color.white.opacity(0.35) // Light mode
        ///
        /// | シーン例               | Why            |
        /// | ------------------ | -------------- |
        /// | 💬 説明テキストの補足       | 読まなくてもいい情報をぼかす |
        /// | ⏱ 時間表示の単位（秒とかms）   | 主数値より弱く見せたい    |
        /// | 🕳 非アクティブなラベル、状態表示 | グレー系代わりの白系ミュート |
        static let textMuted = Color("moonTextMuted")
        /// アクセント色（既存の拡張から）
        static let accentBlue = Color.moonAccentBlue
        /// エラー背景色（既存の拡張から）
        static let errorBackground = Color.moonErrorBackground
        /// サーフェス色（薄いグレーの代替）
        static let surfaceSecondary = Color.white.opacity(0.1)
        /// サーフェス色（より薄いグレーの代替）
        static let surfaceTertiary = Color.white.opacity(0.3)
        /// シャドウ色（影効果用）
        static let shadowColor = Color.black
        /// 成功状態色（緑の代替）
        static let statusSuccess = Color.green
        /// プラスボタン用アクセントグリーン
        static let accentGreen = Color(red: 0.0, green: 0.78, blue: 0.59) // #00C896
        /// マイナスボタン用アクセントオレンジ
        static let accentOrange = Color(red: 1.0, green: 0.54, blue: 0.40) // #FF8A65
        /// プログレス表示用アクセントブルー（強化版）
        static let accentBlueStrong = Color(red: 0.29, green: 0.62, blue: 1.0) // #4A9EFF
    }
    /// 宇宙空間をテーマにした背景カラー
    enum CosmosColors {
        static let background = Color(hex: "#0A0F1C")
        /// カード背景色（黒ベースの薄いグレー）
        static let cardBackground = BlackColors.secondary
        /// カード背景（代替・サブtle用）
        /// 例: サイドメニューのDuration +/- ブロック背景
        static let cardBackgroundAlt = WhiteColors.primary.opacity(0.10)
    }
    /// TsukiSound風のAudio画面スタイル（SkyTone.night）
    enum SkyToneColors {
        /// 背景グラデーション開始色
        static let nightStart = Color(hex: "#0B0F18")
        /// 背景グラデーション終了色
        static let nightEnd = Color(hex: "#141A26")
        /// 背景グラデーション
        static var backgroundGradient: LinearGradient {
            LinearGradient(
                colors: [nightStart, nightEnd],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        /// テキスト色（白95%）- 最重要
        static let textPrimary = Color.white.opacity(0.95)
        /// テキスト色（白80%）- 重要
        static let textSecondary = Color.white.opacity(0.8)
        /// テキスト色（白70%）- 補助
        static let textTertiary = Color.white.opacity(0.7)
        /// テキスト色（白60%）- 控えめ
        static let textQuaternary = Color.white.opacity(0.6)
        /// テキスト色（白50%）- 薄い
        static let textQuinary = Color.white.opacity(0.5)
        /// カード背景グラデーション
        static var cardGradient: LinearGradient {
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        /// カード枠線グラデーション
        static var cardBorderGradient: LinearGradient {
            LinearGradient(
                colors: [Color.white.opacity(0.15), Color.white.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        /// アクセントブルー（ボタン・リンク等）
        static let accentBlue = Color.moonAccentBlue
        /// アクセントオレンジ（削除・警告等）
        static let accentOrange = Color(red: 1.0, green: 0.54, blue: 0.40) // #FF8A65
    }
    /// セマンティック無視の純粋な色（視覚的アクセント用）
    enum PureColors {
        /// 白テキスト色（全体統一用）
        /// | ケース                                           | textWhite を使う理由                       |
        /// | --------------------------------------------- | ------------------------------------- |
        /// | 🎯 完全な黒背景に浮かせるアイコン（小さい）                       | `.moonTextPrimary` やとαがかかって**ぼやける**から |
        /// | 🎯 アニメーションやエフェクト内の強調白                         | セマンティック無視の**視覚的アクセント**として使う           |
        /// | 🎯 エラー時の「×」やチェックマークなど、**文字以外**のグラフィックで白が必要なとき | 記号的意味が強くて、意味ではなく「色」としての白が必要な場合        |
        static let textWhite = Color.white
        /// 強調用イエロー（STARTパルス時の一時色）
        /// 視覚的アクセントとしてのみ使用（セマンティック無視）
        static let accentYellow = Color.yellow
    }
    /// 黒ベース用途別カラー（グレー階層）
    enum BlackColors {
        /// プライマリ黒（純粋な黒）
        static let primary = Color.black
        /// セカンダリ黒（濃いグレー）
        /// 用途: カード背景、セクション背景
        static let secondary = Color(red: 0.1, green: 0.1, blue: 0.1)
        /// ターシャリ黒（中間グレー）
        /// 用途: 入力欄背景、ボタン背景
        static let tertiary = Color(red: 0.15, green: 0.15, blue: 0.15)
        /// サーフェス黒（薄いグレー）
        /// 用途: ホバー状態、選択状態
        static let surface = Color(red: 0.2, green: 0.2, blue: 0.2)
        /// ストローク黒（境界線用）
        /// 用途: 枠線、区切り線、ボーダー
        static let stroke = Color(red: 0.25, green: 0.25, blue: 0.25)
    }
    /// 白ベースの用途別カラー（テキスト用に維持）
    enum WhiteColors {
        /// プライマリ白（完全な白）
        static let primary = Color.white
        /// セカンダリ白（テキスト弱め表示用）
        /// 用途: サブテキスト、説明文、非アクティブな状態
        static let secondary = Color.white.opacity(0.6)
        /// プレースホルダー白（アイコンや補助要素用）
        /// 用途: 編集アイコン、補助記号、ヒント表示
        static let placeholder = Color.white.opacity(0.3)
        /// サーフェス白（背景ガラス風）
        /// 用途: カード背景、入力欄背景、レイヤー分け
        static let surface = Color.white.opacity(0.05)
        /// ストローク白（枠線用）
        /// 用途: カード枠線、区切り線、ボーダー
        static let stroke = Color.white.opacity(0.15)
    }
    // MARK: - Corner Radius
    enum CornerRadius {
        /// 小さい角丸（6pt）
        static let small: CGFloat = 6
        /// 中程度の角丸（8pt）
        static let medium: CGFloat = 8
        /// 大きい角丸（12pt）
        static let large: CGFloat = 12
        /// 特大角丸（30pt）
        static let extraLarge: CGFloat = 30
    }
    // MARK: - Padding
    enum Padding {
        /// 極小パディング（4pt）
        static let extraSmall: CGFloat = 4
        /// 小さいパディング（8pt）
        static let small: CGFloat = 8
        /// 中程度のパディング（12pt）
        static let medium: CGFloat = 12
        /// 大きいパディング（16pt）
        static let large: CGFloat = 16
        /// 特大パディング（24pt）
        static let extraLarge: CGFloat = 24
        /// カード内パディング
        static let card: CGFloat = 12
        /// カードの左右余白（全カード統一用）
        static let cardHorizontal: CGFloat = 12
        /// セクション間パディング
        static let section: CGFloat = 24
    }
    // MARK: - Spacing
    enum Spacing {
        /// 極小スペース（2pt）
        static let extraSmall: CGFloat = 2
        /// 小さいスペース（4pt）
        static let small: CGFloat = 4
        /// 中程度のスペース（8pt）
        static let medium: CGFloat = 8
        /// 大きいスペース（12pt）
        static let large: CGFloat = 12
        /// 特大スペース（16pt）
        static let extraLarge: CGFloat = 16
        /// カード間スペース
        static let card: CGFloat = 16
        /// セクション間スペース
        static let section: CGFloat = 24
    }
    // MARK: - Font Sizes
    enum FontSize {
        /// キャプション（12pt）
        static let caption: CGFloat = 12
        /// サブヘッドライン（15pt）
        static let subheadline: CGFloat = 15
        /// ボディ（17pt）
        static let body: CGFloat = 17
        /// ヘッドライン（17pt）
        static let headline: CGFloat = 17
        /// タイトル3（20pt）
        static let title3: CGFloat = 20
        /// タイトル2（22pt）
        static let title2: CGFloat = 22
        /// タイトル（28pt）
        static let title: CGFloat = 28
        /// フッター日付（16pt）
        static let footerDate: CGFloat = 16
        /// タイマー表示（65pt）
        static let timerDisplay: CGFloat = 65
        // MARK: - Dynamic Type 対応サイズ
        /// アクセシビリティ特大（14pt）
        static let accessibilityExtraLarge: CGFloat = 14
        /// アクセシビリティ大（16pt）
        static let accessibilityLarge: CGFloat = 16
        /// アクセシビリティ中（18pt）
        static let accessibilityMedium: CGFloat = 18
        /// デフォルト（20pt）
        static let defaultSize: CGFloat = 20
    }
    // MARK: - Fonts
    enum Fonts {
        /// ラベル用フォント（Nunitoのやわらかさ）
        static var label: Font {
            Font.custom("Nunito-Regular", size: FontSize.body)
        }
        /// 太字ラベル用フォント（Nunitoのやわらかさ）
        static var labelBold: Font {
            Font.custom("Nunito-Bold", size: FontSize.body)
        }
        /// セクションタイトル用フォント（Nunitoのやわらかさ）
        static var sectionTitle: Font {
            Font.custom("Nunito-Regular", size: FontSize.subheadline)
        }
        /// 数値表示用フォント（宇宙船ディスプレイ感）
        static var numericLabel: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: FontSize.body, weight: .regular, design: .monospaced)
        }
        /// キャプション用フォント（Nunitoのやわらかさ）
        static var caption: Font {
            Font.custom("Nunito-Regular", size: FontSize.caption)
        }
        /// タイトル用フォント（Nunitoのやわらかさ）
        static var title: Font {
            Font.custom("Nunito-Bold", size: FontSize.title3)
        }
        /// ナビゲーションタイトル用フォント（Nunitoのやわらかさ）
        static var navigationTitle: Font {
            Font.custom("Nunito-Bold", size: FontSize.headline)
        }
        /// SF Symbols 用の小サイズフォント（12pt程度）
        static var symbolSmall: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: FontSize.caption, weight: .regular)
        }
        /// SF Symbols 用の中サイズフォント（16pt程度）
        static var symbolMedium: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: FontSize.subheadline, weight: .medium)
        }
        /// SF Symbols 用の大サイズフォント（22pt程度）
        static var symbolLarge: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: FontSize.title2, weight: .regular)
        }
        /// SF Symbols 用の特大サイズフォント（28pt程度）
        static var symbolExtraLarge: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: FontSize.title, weight: .regular)
        }
        /// タイマー表示用フォント（🚨 重要：絶対に変更禁止 🚨）
        /// 必ずシステムフォント .rounded を使用すること
        /// 理由：視認性・読みやすさ・数字表示最適化のため
        /// カスタムフォント（Nunitoなど）は使用しないこと
        static var timerDisplay: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: FontSize.timerDisplay, weight: .bold, design: .rounded)
        }
        /// フッター日付用フォント（🚨 重要：絶対に変更禁止 🚨）
        /// 必ずシステムフォント .monospaced を使用すること
        /// 理由：宇宙船ディスプレイ感・日付の正確性・等幅表示のため
        /// カスタムフォント（Nunitoなど）は使用しないこと
        static var footerDate: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: FontSize.footerDate, weight: .bold, design: .monospaced)
        }
    }
    // MARK: - Animation
    enum Animation {
        /// 短いアニメーション（0.2秒）
        static let short: Double = 0.2
        /// 中程度のアニメーション（0.3秒）
        static let medium: Double = 0.3
        /// 長いアニメーション（0.5秒）
        static let long: Double = 0.5
        /// セッション終了アニメーション（0.8秒）
        static let sessionEnd: Double = 0.8
    }
    // MARK: - Star Animation
    enum StarAnimation {
        /// 通常時の星の数
        static let normalStarCount: Int = 40
        /// Reduce Motion 時の星の数
        static let reducedStarCount: Int = 20
        /// 通常時のFPS
        static let normalFPS: Double = 1 / 60
        /// Reduce Motion 時のFPS
        static let reducedFPS: Double = 1 / 30
        /// 通常時のアニメーション速度範囲
        static let normalDurationRange: ClosedRange<Double> = 24 ... 40
        /// Reduce Motion 時のアニメーション速度範囲
        static let reducedDurationRange: ClosedRange<Double> = 30 ... 50
    }
}
#if canImport(UIKit)
    import UIKit
#endif
extension DesignTokens {
    enum UIKitFonts {
        static var numericLabel: UIFont {
            #if canImport(UIKit)
                return UIFont.monospacedDigitSystemFont(ofSize: FontSize.body, weight: .medium)
            #else
                fatalError("UIFont is only available on UIKit platforms.")
            #endif
        }
        /// ナビゲーションタイトル用UIFont（Nunitoのやわらかさ）
        static var navigationTitle: UIFont {
            #if canImport(UIKit)
                return UIFont(name: "Nunito-Bold", size: FontSize.headline)
                    ?? UIFont.boldSystemFont(ofSize: FontSize.headline)
            #else
                fatalError("UIFont is only available on UIKit platforms.")
            #endif
        }
    }
    enum UIColors {
        static var textWhite: UIColor {
            #if canImport(UIKit)
            // Assetを読むけど、"固定カラー"として設定したやつだけ使う
            // （Appearance: Anyに設定した色）
            return UIColor(named: "moonTextPrimary") ?? UIColor.white
            #else
            fatalError("UIColor is only available on UIKit platforms.")
            #endif
        }
    }
}
// MARK: - Icon Colors (Semantic)
extension DesignTokens {
    enum IconColors {
        /// Edit系アイコン（鉛筆）用の標準色
        static let pencil = MoonColors.accentBlue
        /// 無効状態のアイコン色（視覚的に弱める）
        static let pencilDisabled = MoonColors.textMuted
    }
}
// MARK: - Color Extension for Semantic Shortcuts
extension Color {
    // Pure Colors への直接アクセス
    static let textWhite = DesignTokens.PureColors.textWhite
}

import SwiftUI

/// デザイン定数の一元管理
/// Asset Catalog からカラーを参照し、Light/Dark モードに対応
enum DesignTokens {
    // MARK: - Colors (意味別グルーピング)

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
    }

    /// 宇宙空間をテーマにした背景カラー
    enum CosmosColors {
        /// 背景色（既存の拡張から）
        static let background = Color.cosmosBackground

        /// カード背景色（Light/Dark モード対応）
        static let cardBackground = Color.cosmosCardBackground
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
    }

    /// 白ベースの用途別カラー（意味づけされたopacity）
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

        /// ボディ（17pt）
        static let body: CGFloat = 17

        /// サブヘッドライン（15pt）
        static let subheadline: CGFloat = 15

        /// ヘッドライン（17pt）
        static let headline: CGFloat = 17

        /// タイトル3（20pt）
        static let title3: CGFloat = 20

        /// タイトル2（22pt）
        static let title2: CGFloat = 22

        /// タイトル（28pt）
        static let title: CGFloat = 28
    }

    // MARK: - Fonts

    enum Fonts {
        static var label: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 17, weight: .regular, design: .default)
        }
        static var labelBold: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 17, weight: .bold, design: .default)
        }
        static var sectionTitle: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 15, weight: .regular, design: .default)
        }
        static var numericLabel: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 17, weight: .regular, design: .default)
        }
        static var caption: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 12, weight: .regular, design: .default)
        }
        static var title: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 20, weight: .bold, design: .default)
        }
        static var timerDisplay: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 65, weight: .bold, design: .rounded)
        }
        static var footerDate: Font {
            // swiftlint:disable:next discouraged-font-usage
            Font.system(size: 16, weight: .bold, design: .monospaced)
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
                return UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
            #else
                fatalError("UIFont is only available on UIKit platforms.")
            #endif
        }
    }

    enum UIColors {
        static var textWhite: UIColor {
            #if canImport(UIKit)
                return UIColor.white
            #else
                fatalError("UIColor is only available on UIKit platforms.")
            #endif
        }
    }
}

// MARK: - Color Extension for Semantic Shortcuts
import SwiftUI

extension Color {
    // Pure Colors への直接アクセス
    static let textWhite = DesignTokens.PureColors.textWhite
}

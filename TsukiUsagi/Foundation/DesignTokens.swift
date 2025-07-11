import SwiftUI

/// デザイン定数の一元管理
/// Asset Catalog からカラーを参照し、Light/Dark モードに対応
enum DesignTokens {
    // MARK: - Colors (Asset Catalog 参照)

    enum Colors {
        /// カード背景色（Light/Dark モード対応）
        static let moonCardBG = Color.moonCardBackground.opacity(0.15)

        /// プライマリテキスト色（Light/Dark モード対応）
        static let moonTextPrimary = Color("moonTextPrimary")

        /// 白テキスト色（全体統一用）
        static let textWhite = Color.white

        /// セカンダリテキスト色（Light/Dark モード対応）
        static let moonTextSecondary = Color("moonTextSecondary")

        /// ミュートテキスト色（Light/Dark モード対応）
        static let moonTextMuted = Color("moonTextMuted")

        /// 背景色（既存の拡張から）
        static let moonBackground = Color.moonBackground

        /// アクセント色（既存の拡張から）
        static let moonAccentBlue = Color.moonAccentBlue

        /// エラー背景色（既存の拡張から）
        static let moonErrorBackground = Color.moonErrorBackground
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
        // swiftlint:disable:next discouraged-font-usage
        static var label: Font {
            Font.system(size: 17, weight: .regular, design: .default) // [理由] セマンティック名の実体定義としてのみ許可
        }
        // swiftlint:disable:next discouraged-font-usage
        static var labelBold: Font {
            Font.system(size: 17, weight: .bold, design: .default) // [理由] セマンティック名の実体定義としてのみ許可
        }
        // swiftlint:disable:next discouraged-font-usage
        static var sectionTitle: Font {
            Font.system(size: 15, weight: .regular, design: .default) // [理由] セマンティック名の実体定義としてのみ許可
        }
        // swiftlint:disable:next discouraged-font-usage
        static var numericLabel: Font {
            Font.system(size: 17, weight: .regular, design: .default) // [理由] セマンティック名の実体定義としてのみ許可
        }
        // swiftlint:disable:next discouraged-font-usage
        static var caption: Font {
            Font.system(size: 12, weight: .regular, design: .default) // [理由] セマンティック名の実体定義としてのみ許可
        }
        // swiftlint:disable:next discouraged-font-usage
        static var title: Font {
            Font.system(size: 20, weight: .bold, design: .default) // [理由] セマンティック名の実体定義としてのみ許可
        }
        // swiftlint:disable:next discouraged-font-usage
        static var timerDisplay: Font {
            Font.system(size: 65, weight: .bold, design: .rounded) // [理由] タイマー表示用の特大・丸みデザイン
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

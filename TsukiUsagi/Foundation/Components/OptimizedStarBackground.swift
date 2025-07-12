import SwiftUI

/// 最適化された星背景レイヤー
/// FPS制御とReduce Motion対応でパフォーマンスを向上
struct OptimizedStarBackground: ViewModifier {
    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    let starCount: Int
    let staticStarCount: Int
    let angle: Angle
    var durationRange: ClosedRange<Double>
    var sizeRange: ClosedRange<CGFloat>
    var spawnArea: StarSpawnArea?

    // MARK: - Initializers

    /// 標準的な星背景
    /// - Parameters:
    ///   - starCount: 流れる星の数
    ///   - staticStarCount: 固定星の数
    ///   - angle: 流れる方向
    ///   - durationRange: アニメーション時間範囲
    ///   - sizeRange: 星のサイズ範囲
    ///   - spawnArea: 生成エリア
    init(
        starCount: Int = DesignTokens.StarAnimation.normalStarCount,
        staticStarCount: Int = DesignTokens.StarAnimation.normalStarCount,
        angle: Angle = .degrees(135),
        durationRange: ClosedRange<Double> = DesignTokens.StarAnimation.normalDurationRange,
        sizeRange: ClosedRange<CGFloat> = 2 ... 4,
        spawnArea: StarSpawnArea? = nil
    ) {
        self.starCount = starCount
        self.staticStarCount = staticStarCount
        self.angle = angle
        self.durationRange = durationRange
        self.sizeRange = sizeRange
        self.spawnArea = spawnArea
    }

    /// Reduce Motion対応の星背景
    /// アクセシビリティ設定に応じて自動調整
    init(
        adaptive starCount: Int = DesignTokens.StarAnimation.normalStarCount,
        staticStarCount: Int = DesignTokens.StarAnimation.normalStarCount,
        angle: Angle = .degrees(135),
        normalDurationRange: ClosedRange<Double> = DesignTokens.StarAnimation.normalDurationRange,
        reducedDurationRange _: ClosedRange<Double> = DesignTokens.StarAnimation.reducedDurationRange,
        sizeRange: ClosedRange<CGFloat> = 2 ... 4,
        spawnArea: StarSpawnArea? = nil
    ) {
        self.starCount = starCount
        self.staticStarCount = staticStarCount
        self.angle = angle
        durationRange = normalDurationRange // デフォルト値として設定
        self.sizeRange = sizeRange
        self.spawnArea = spawnArea
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content.background(
            TimelineView(
                .animation(
                    minimumInterval: reduceMotion
                        ? DesignTokens.StarAnimation.reducedFPS
                        : DesignTokens.StarAnimation.normalFPS
                )
            ) { _ in
                ZStack {
                    // 背景色
                    DesignTokens.Colors.moonBackground
                        .ignoresSafeArea()

                    // 固定星
                    StaticStarsView(starCount: reduceMotion ? staticStarCount / 2 : staticStarCount)
                        .allowsHitTesting(false)

                    // 流れる星
                    FlowingStarsView(
                        starCount: reduceMotion ? starCount / 2 : starCount,
                        angle: angle,
                        durationRange: reduceMotion ? DesignTokens.StarAnimation.reducedDurationRange : durationRange,
                        sizeRange: sizeRange,
                        spawnArea: spawnArea
                    )
                }
            }
        )
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// 標準的な星背景を適用
    func starBackground(
        starCount: Int = DesignTokens.StarAnimation.normalStarCount,
        staticStarCount: Int = DesignTokens.StarAnimation.normalStarCount,
        angle: Angle = .degrees(135),
        durationRange: ClosedRange<Double> = DesignTokens.StarAnimation.normalDurationRange,
        sizeRange: ClosedRange<CGFloat> = 2 ... 4,
        spawnArea: StarSpawnArea? = nil
    ) -> some View {
        modifier(OptimizedStarBackground(
            starCount: starCount,
            staticStarCount: staticStarCount,
            angle: angle,
            durationRange: durationRange,
            sizeRange: sizeRange,
            spawnArea: spawnArea
        ))
    }

    /// 適応的な星背景を適用（Reduce Motion対応）
    func adaptiveStarBackground(
        starCount: Int = DesignTokens.StarAnimation.normalStarCount,
        staticStarCount: Int = DesignTokens.StarAnimation.normalStarCount,
        angle: Angle = .degrees(135),
        normalDurationRange: ClosedRange<Double> = DesignTokens.StarAnimation.normalDurationRange,
        reducedDurationRange: ClosedRange<Double> = DesignTokens.StarAnimation.reducedDurationRange,
        sizeRange: ClosedRange<CGFloat> = 2 ... 4,
        spawnArea: StarSpawnArea? = nil
    ) -> some View {
        modifier(OptimizedStarBackground(
            adaptive: starCount,
            staticStarCount: staticStarCount,
            angle: angle,
            normalDurationRange: normalDurationRange,
            reducedDurationRange: reducedDurationRange,
            sizeRange: sizeRange,
            spawnArea: spawnArea
        ))
    }

    /// 軽量な星背景を適用（パフォーマンス重視）
    func lightStarBackground() -> some View {
        modifier(OptimizedStarBackground(
            starCount: DesignTokens.StarAnimation.reducedStarCount,
            staticStarCount: DesignTokens.StarAnimation.reducedStarCount,
            angle: .degrees(135),
            durationRange: DesignTokens.StarAnimation.reducedDurationRange,
            sizeRange: 1 ... 3
        ))
    }
}

// MARK: - Preview

#Preview("OptimizedStarBackground") {
    VStack(spacing: 20) {
        // 標準背景
        VStack {
            Text("Standard Background")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.Colors.moonTextPrimary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .starBackground()

        // 軽量背景
        VStack {
            Text("Light Background")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.Colors.moonTextPrimary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .lightStarBackground()

        // 適応的背景
        VStack {
            Text("Adaptive Background")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(DesignTokens.Colors.moonTextPrimary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .adaptiveStarBackground()
    }
    .padding()
    .previewColorSchemes()
    .previewEnvironment(PreviewData.EnvironmentValues.normal)
    .previewEnvironment(PreviewData.EnvironmentValues.accessibility)
}

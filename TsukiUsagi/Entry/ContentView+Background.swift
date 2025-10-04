import SwiftUI
import Foundation

extension ContentView {
    // MARK: - Background Components

    struct BackgroundLayerParams {
        let size: CGSize
        let safeAreaInsets: EdgeInsets
        let staticStarCount: Int
        let flowingStarCount: Int
        let isLowPowerMode: Bool
        let isSessionFinished: Bool
        let shouldAnimateStars: Bool
        let isLandscape: Bool
    }

    @ViewBuilder
    func backgroundLayer(params: BackgroundLayerParams) -> some View {
        // 背景レイヤ
        BackgroundGradientView().ignoresSafeArea()
        AwakeEnablerView(hidden: true)
        StaticStarsView(starCount: params.staticStarCount)

        // セッション未完了かつアニメーション可時に星エフェクト表示
        if !params.isSessionFinished && params.shouldAnimateStars {
            let baseCount = params.isLowPowerMode ? 24 : params.flowingStarCount
            let flowingCount = params.isLandscape ? Int(Double(baseCount) * 0.7) : baseCount
            let dur: ClosedRange<Double> = params.isLandscape ? 28 ... 44 : 24 ... 40

            FlowingStarsView(
                starCount: flowingCount,
                angle: .degrees(90), // 下向き
                durationRange: dur,
                sizeRange: 2 ... 4,
                spawnArea: nil
            )
            FlowingStarsView(
                starCount: flowingCount,
                angle: .degrees(-90), // 上向き
                durationRange: dur,
                sizeRange: 2 ... 4,
                spawnArea: nil
            )
        }
    }
}

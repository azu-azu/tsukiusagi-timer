import SwiftUI

// MARK: - 🎭 Adaptive Animation Views

/// GPU アクセラレーション条件付き適用のView拡張
extension View {
    @ViewBuilder
    func conditionalDrawingGroup(_ condition: Bool) -> some View {
        if condition {
            self.drawingGroup()
        } else {
            self
        }
    }
}

/// アダプティブ流れ星View
struct AdaptiveFlowingStarsView: View {
    @StateObject private var controller = AdaptiveAnimationEngine()
    @Environment(\.scenePhase) private var scenePhase

    let baseStarCount: Int
    let angle: Angle
    let durationRange: ClosedRange<Double>
    let sizeRange: ClosedRange<CGFloat>
    let spawnArea: StarSpawnArea?

    var body: some View {
        Group {
            if !controller.isBackgroundMode && controller.effectiveStarCount > 0 {
                FlowingStarsView(
                    starCount: controller.effectiveStarCount,
                    angle: angle,
                    durationRange: durationRange,
                    sizeRange: sizeRange,
                    spawnArea: spawnArea
                )
                .conditionalDrawingGroup(controller.shouldUseGPUAcceleration)
                .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            controller.updateScenePhase(newPhase)
        }
    }
}

/// アダプティブスパークル星View
struct AdaptiveSparkleStarsView: View {
    @StateObject private var controller = AdaptiveAnimationEngine()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !controller.isBackgroundMode {
                SparkleStarsView()
                    .conditionalDrawingGroup(controller.shouldUseGPUAcceleration)
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            controller.updateScenePhase(newPhase)
        }
    }
}

/// アダプティブ月View
struct AdaptiveMoonView: View {
    @StateObject private var controller = AdaptiveAnimationEngine()
    @Environment(\.scenePhase) private var scenePhase

    let moonSize: CGFloat
    let glitterText: String
    let size: CGSize

    var body: some View {
        MoonView(moonSize: moonSize, glitterText: glitterText, size: size)
            .conditionalDrawingGroup(controller.shouldUseGPUAcceleration)
            .onChange(of: scenePhase) { _, newPhase in
                controller.updateScenePhase(newPhase)
            }
    }
}

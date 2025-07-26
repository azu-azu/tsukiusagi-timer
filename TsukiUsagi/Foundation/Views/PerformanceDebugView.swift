import SwiftUI

// MARK: - 📊 Performance Debug View (開発用)

struct PerformanceDebugView: View {
    @StateObject private var controller = AdaptiveAnimationController()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            debugHeader
            debugMetrics
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Private Views

    private var debugHeader: some View {
        Text("🎛 Performance Monitor")
            .font(DesignTokens.Fonts.labelBold)
    }

    private var debugMetrics: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quality: \(controller.animationQuality)")
            Text("Stars: \(controller.effectiveStarCount)")
            Text("Sparkle Interval: \(String(format: "%.2f", controller.effectiveSparkleInterval))s")
            Text("GPU Accel: \(controller.shouldUseGPUAcceleration ? "ON" : "OFF")")
            Text("Low Power: \(controller.isLowPowerMode ? "ON" : "OFF")")
            Text("Background: \(controller.isBackgroundMode ? "ON" : "OFF")")
            Text("Memory: \(controller.memoryPressure)")
        }
        .font(DesignTokens.Fonts.caption)
        .foregroundColor(DesignTokens.MoonColors.textSecondary)
    }
}

// MARK: - 🚀 Demo View

struct AdaptiveAnimationDemoView: View {
    var body: some View {
        ZStack {
            backgroundLayer
            animationLayers
            debugOverlay
        }
    }

    // MARK: - Private Views

    private var backgroundLayer: some View {
        Color.black.ignoresSafeArea()
    }

    private var animationLayers: some View {
        Group {
            AdaptiveFlowingStarsView(
                baseStarCount: 50,
                angle: .degrees(90),
                durationRange: 24...40,
                sizeRange: 2...4,
                spawnArea: nil
            )

            AdaptiveSparkleStarsView()

            AdaptiveMoonView(
                moonSize: 200,
                glitterText: "✨",
                size: UIScreen.main.bounds.size
            )
        }
    }

    private var debugOverlay: some View {
        VStack {
            Spacer()
            HStack {
                PerformanceDebugView()
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    AdaptiveAnimationDemoView()
}

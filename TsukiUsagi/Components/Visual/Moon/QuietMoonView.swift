import SwiftUI

struct QuietMoonView: View {
    private let title  = "Quiet Moon"
    private let paddingY: CGFloat = 60
    private let bodyText = MoonMessage.random().lines.joined(separator: "\n")

    let size: CGSize
    let safeAreaInsets: EdgeInsets

    // MARK: - Computed Properties

    /// 動的高さ計算（ふじこ式）
    private var dynamicHeight: CGFloat { min(size.height * 0.5, 400) }

    /// 横画面判定
    private var isLandscape: Bool {
        size.width > size.height
    }

    /// 向きに応じた上部パディング
    private var topPadding: CGFloat {
        // 縦横共通：ノッチを避けた上で適切なスペースを確保
        let deviceSpecificPadding: CGFloat = {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                // iPhone: ノッチ/Dynamic Islandを避ける
                return isLandscape ? 30 : 20 // 横画面時は少し多め ： 縦画面時は20pt
            case .pad:
                // iPad: より余裕を持たせる
                return isLandscape ? 40 : 30 // 横画面時は少し多め ： 縦画面時は30pt
            default:
                return isLandscape ? 20 : 15 // 横画面時は少し多め
            }
        }()

        let calculatedPadding = max(paddingY, safeAreaInsets.top + deviceSpecificPadding)

        // デバッグ用ログ（開発時のみ）
        #if DEBUG
        print("🌙 QuietMoonView - topPadding calculation:")
        print("  - paddingY: \(paddingY)")
        print("  - safeAreaInsets.top: \(safeAreaInsets.top)")
        print("  - deviceSpecificPadding: \(deviceSpecificPadding)")
        print("  - calculatedPadding: \(calculatedPadding)")
        print("  - isLandscape: \(isLandscape)")
        #endif

        // ノッチを避けた上で、最小限のスペースを保証
        return calculatedPadding
    }

    /// 向きに応じた左側パディング（ノッチ回避用）
    private var leftPadding: CGFloat {
        if isLandscape {
            // 横画面時：左側のノッチ/Dynamic Islandを避ける
            let deviceSpecificPadding: CGFloat = {
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    // iPhone: ノッチ/Dynamic Islandを避ける
                    return 20
                case .pad:
                    // iPad: より余裕を持たせる
                    return 30
                default:
                    return 15
                }
            }()

            return max(24, safeAreaInsets.leading + deviceSpecificPadding)
        } else {
            // 縦画面時：従来通り
            return 24
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text(title)
                    .glitter(size: 24, resourceName: "gold")
                    .frame(maxWidth: .infinity)

                SelectableTextView(
                    text: bodyText,
                    font: avenirNextUIFont(size: 18, weight: .regular, design: .monospaced),
                    textColor: .white
                )
                .frame(height: dynamicHeight)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, leftPadding)
                .padding(.trailing, 24)
                .padding(.bottom, 8)

                Spacer()
            }
            .padding(.top, topPadding)

            FlowingStarsView(
                starCount: 20,
                angle: .degrees(135),
                durationRange: 24...40,
                sizeRange: 2...4,
                spawnArea: nil
            )
            .ignoresSafeArea()
        }
        .background(Color.clear)
        .accessibilityElement(children: .combine)
    }
}

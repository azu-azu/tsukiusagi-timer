import SwiftUI

struct MainPanel: View {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    let isLandscape: Bool
    @ObservedObject var timerVM: TimerViewModel
    // ← let から @ObservedObject に変更
    let moonTitle: String
    let landscapeMargin: CGFloat
    let moonPortraitYOffsetRatio: CGFloat
    let moonLandscapeYOffsetRatio: CGFloat
    var isQuietMoonFocused: FocusState<Bool>.Binding
    @Binding var showingEditRecord: Bool
    let isMoonAnimationActive: Bool

    var body: some View {
        // let _ = print(
        //   "🌙 MainPanel - isSessionFinished:\n"
        //   + "  \(timerVM.isSessionFinished),\n"
        //   + "  isWorkSession: \(timerVM.isWorkSession)")

        GeometryReader { geo2 in

            let contentSize = geo2.size
            // GeometryReaderのsafeAreaに統一
            let safeTop = (geo2.safeAreaInsets.top.isFinite && !geo2.safeAreaInsets.top.isNaN) ? geo2.safeAreaInsets.top : 0
            let safeBottom = (geo2.safeAreaInsets.bottom.isFinite && !geo2.safeAreaInsets.bottom.isNaN) ? geo2.safeAreaInsets.bottom : 0

            // 入力の安定化
            let contentW = max(0, (contentSize.width.isFinite && !contentSize.width.isNaN) ? contentSize.width : 0)
            let contentH = max(0, (contentSize.height.isFinite && !contentSize.height.isNaN) ? contentSize.height : 0)
            let ratioPortraitRaw = (moonPortraitYOffsetRatio.isFinite && !moonPortraitYOffsetRatio.isNaN) ? moonPortraitYOffsetRatio : 0
            let ratioLandscapeRaw = (moonLandscapeYOffsetRatio.isFinite && !moonLandscapeYOffsetRatio.isNaN) ? moonLandscapeYOffsetRatio : 0
            let ratioPortrait = max(-1, min(ratioPortraitRaw, 1))
            let ratioLandscape = max(-1, min(ratioLandscapeRaw, 1))
            let margin = max(0, (landscapeMargin.isFinite && !landscapeMargin.isNaN) ? landscapeMargin : 0)

            // 動的サイズ計算（副作用なし）
            let baseMoonSize = max(0, min(contentW, contentH) * 0.5)
            let moonSize = max(120, min(baseMoonSize, 400))
            let timerHeight = max(0, moonSize / 3)
            let timerSpacing = max(0, min(moonSize * 0.5, 120))

            let setHeight = max(0, moonSize + timerSpacing + timerHeight)

            if timerVM.isSessionFinished {
                // let _ = print("🌙 MainPanel - Showing QuietMoon section")
                // 終了時はQuietMoonViewのみ
                if isLandscape {
                    // let _ = print("🌙 MainPanel - Landscape QuietMoon")
                    // 横画面：左右分割（最高品質版）
                    HStack(spacing: landscapeMargin) {
                        // 左側：QuietMoonView
                        QuietMoonView(
                            size: size,
                            safeAreaInsets: geo2.safeAreaInsets,
                            isAnimationActive: isMoonAnimationActive
                        )
                        .frame(
                            width: max(contentW - margin, 0) * 0.5,
                            height: setHeight
                        )
                        .background(Color.clear)
                        .zIndex(10)
                        .layoutPriority(1)
                        .accessibilityLabel("Quiet Moon Message")
                        .accessibilityHint(
                            "Displays inspirational messages after session completion"
                        )
                        .accessibilityAddTraits(AccessibilityTraits.isHeader)
                        .focused(isQuietMoonFocused)

                        // 右側：RecordedTimesView
                        VStack {
                            Spacer()
                            RecordedTimesView(
                                formattedStartTime: timerVM.formattedStartTime,
                                formattedEndTime: timerVM.formattedEndTime,
                                actualSessionMinutes: timerVM.actualSessionMinutes,
                                onEdit: { showingEditRecord = true }
                            )
                            .sessionVisibility(isVisible: timerVM.isSessionFinished)
                            .sessionEndTransition(timerVM)
                            Spacer()
                        }
                        .frame(
                            width: max(contentW - margin, 0) * 0.5,
                            height: setHeight
                        )
                        .background(Color.clear)
                        .zIndex(10)
                        .layoutPriority(0)
                        .accessibilityLabel("Session Record")
                        .accessibilityHint(
                            "Shows start time, end time, and session " +
                            "duration"
                        )
                    }
                    .frame(width: contentW, height: setHeight, alignment: .center)
                    .offset(y: -(contentH * ratioLandscape))
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                } else {
                    // let _ = print("🌙 MainPanel - Portrait QuietMoon")
                    // 縦画面：QuietMoonのみ（RecordedTimesはContentView側で重ねる）
                    VStack {
                        QuietMoonView(
                            size: size,
                            safeAreaInsets: geo2.safeAreaInsets,
                            isAnimationActive: isMoonAnimationActive
                        )
                        .accessibilityLabel("Quiet Moon Message")
                        .accessibilityHint(
                            "Displays inspirational messages after session completion"
                        )
                        .accessibilityAddTraits(AccessibilityTraits.isHeader)
                        .focused(isQuietMoonFocused)
                    }
                    .frame(width: contentW, height: setHeight, alignment: .center)
                    .offset(y: -(contentH * ratioPortrait))
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            } else {
                // let _ = print("🌙 MainPanel - Showing Timer section")
                // 進行中はMoon+Timerセット
                if isLandscape {
                    // --- Landscape の Moon + Timer 横並び ---
                    let hStackWidth = max(contentW, 0) * 0.8
                    HStack(spacing: landscapeMargin) {
                        // MoonView
                        MoonView(
                            moonSize: moonSize,
                            glitterText: moonTitle,
                            size: size,
                            isAnimationActive: isMoonAnimationActive
                        )
                        .allowsHitTesting(false)
                        .frame(
                            width: max(hStackWidth - margin, 0) * 0.5,
                            height: moonSize
                        )
                        .layoutPriority(1)

                        // TimerPanel
                        VStack {
                            Spacer()
                            TimerPanel(timerVM: timerVM)
                                .frame(
                                    minWidth: moonSize,
                                    maxWidth: moonSize * 1.5,
                                    minHeight: timerHeight,
                                    maxHeight: timerHeight
                                )
                            Spacer()
                        }
                        .frame(
                            width: max(hStackWidth - margin, 0) * 0.5,
                            height: moonSize
                        )
                        .layoutPriority(0)
                    }
                    .frame(width: max(hStackWidth, 0), height: moonSize, alignment: .center)
                    .offset(y: -(contentH * ratioLandscape))
                } else {
                    // 縦画面：従来通り
                    VStack(spacing: timerSpacing) {
                        MoonView(
                            moonSize: moonSize,
                            glitterText: moonTitle,
                            size: size,
                            isAnimationActive: isMoonAnimationActive
                        )
                        .allowsHitTesting(false)

                        TimerPanel(timerVM: timerVM)
                            .frame(
                                minWidth: moonSize,
                                maxWidth: moonSize * 1.5,
                                minHeight: timerHeight,
                                maxHeight: timerHeight
                            )
                    }
                    .frame(width: contentW, height: setHeight, alignment: .center)
                    .offset(y: -(contentH * ratioPortrait))
                }
            }
        }
        // シート提示は上位（ContentView）から
    }
}

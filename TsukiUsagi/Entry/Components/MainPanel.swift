import SwiftUI

struct MainPanel: View {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    let isLandscape: Bool
    let timerVM: TimerViewModel
    let moonTitle: String
    let landscapeMargin: CGFloat
    let moonPortraitYOffsetRatio: CGFloat
    let moonLandscapeYOffsetRatio: CGFloat
    var isQuietMoonFocused: FocusState<Bool>.Binding
    @Binding var showingEditRecord: Bool

    var body: some View {
        GeometryReader { geo2 in
            let contentSize = geo2.size
            let safeTop = geo2.safeAreaInsets.top
            let safeBottom = geo2.safeAreaInsets.bottom

            // 動的サイズ計算（副作用なし）
            let baseMoonSize = min(contentSize.width, contentSize.height) * 0.5
            let moonSize = min(max(baseMoonSize, 120), 400)
            let timerHeight = moonSize / 3
            let timerSpacing = min(moonSize * 0.5, 120)

            let setHeight = moonSize + timerSpacing + timerHeight

            // SafeAreaを考慮した中央
            let centerY = (contentSize.height - safeTop - safeBottom) / 2 + safeTop

            // 縦横別：比率で位置を決定
            let setCenterY: CGFloat = isLandscape
                ? centerY - contentSize.height * moonLandscapeYOffsetRatio // 横画面
                : centerY - contentSize.height * moonPortraitYOffsetRatio // 縦画面

            if timerVM.isSessionFinished {
                // 終了時はQuietMoonViewのみ
                if isLandscape {
                    // 横画面：左右分割（最高品質版）
                    HStack(spacing: landscapeMargin) {
                        // 左側：QuietMoonView
                        QuietMoonView(size: size, safeAreaInsets: safeAreaInsets)
                            .frame(width: (contentSize.width - landscapeMargin) * 0.5,
                                    height: setHeight)
                            .background(Color.clear)
                            .zIndex(10)
                            .layoutPriority(1)
                            .accessibilityLabel("Quiet Moon Message")
                            .accessibilityHint(
                                "Displays inspirational messages after session completion"
                            )
                            .accessibilityAddTraits(.isHeader)
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
                        .frame(width: (contentSize.width - landscapeMargin) * 0.5, height: setHeight)
                        .background(Color.clear)
                        .zIndex(10)
                        .layoutPriority(0)
                        .accessibilityLabel("Session Record")
                        .accessibilityHint(
                            "Shows start time, end time, and session " +
                            "duration"
                        )
                    }
                    .frame(width: contentSize.width, height: setHeight)
                    .position(x: contentSize.width / 2, y: setCenterY)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                } else {
                    // 縦画面：従来通り
                    VStack {
                        QuietMoonView(size: size, safeAreaInsets: safeAreaInsets)
                            .accessibilityLabel("Quiet Moon Message")
                            .accessibilityHint(
                                "Displays inspirational messages after session completion"
                            )
                            .accessibilityAddTraits(.isHeader)
                            .focused(isQuietMoonFocused)
                    }
                    .frame(width: contentSize.width, height: setHeight)
                    .position(x: contentSize.width / 2, y: setCenterY)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            } else {
                // 進行中はMoon+Timerセット
                if isLandscape {
                    // --- Landscape の Moon + Timer 横並び ---
                    let hStackWidth = contentSize.width * 0.8
                    HStack(spacing: landscapeMargin) {
                        // MoonView
                        MoonView(
                            moonSize: moonSize,
                            glitterText: moonTitle,
                            size: size
                        )
                        .allowsHitTesting(false)
                        .frame(width: (hStackWidth - landscapeMargin) * 0.5, height: moonSize)
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
                        .frame(width: (hStackWidth - landscapeMargin) * 0.5, height: moonSize)
                        .layoutPriority(0)
                    }
                    .frame(width: hStackWidth, height: moonSize)
                    .position(x: contentSize.width / 2, y: setCenterY)
                } else {
                    // 縦画面：従来通り
                    VStack(spacing: timerSpacing) {
                        MoonView(
                            moonSize: moonSize,
                            glitterText: moonTitle,
                            size: size
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
                    .frame(width: contentSize.width,
                        height: setHeight)
                    .position(x: contentSize.width / 2,
                            y: setCenterY)
                }
            }
        }
    }
}
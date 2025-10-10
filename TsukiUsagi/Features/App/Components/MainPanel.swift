import SwiftUI

struct MainPanel: View {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
    let isLandscape: Bool
    @EnvironmentObject private var timerVM: TimerViewModel
    // ← @ObservedObject から @EnvironmentObject に変更
    let moonTitle: String
    let landscapeMargin: CGFloat
    let moonPortraitYOffsetRatio: CGFloat
    let moonLandscapeYOffsetRatio: CGFloat
    var isQuietMoonFocused: FocusState<Bool>.Binding
    @Binding var showingEditRecord: Bool
    let isMoonAnimationActive: Bool

    var body: some View {

        GeometryReader { geo2 in

            let contentSize = geo2.size
            // GeometryReaderのsafeAreaに統一
            let safeTop = (
                geo2.safeAreaInsets.top.isFinite
                && !geo2.safeAreaInsets.top.isNaN
            )
                ? geo2.safeAreaInsets.top
                : 0
            let safeBottom = (
                geo2.safeAreaInsets.bottom.isFinite
                && !geo2.safeAreaInsets.bottom.isNaN
            )
                ? geo2.safeAreaInsets.bottom
                : 0

            // 入力の安定化（ローカル関数を使わず式で記述）
            let contentW = (
                contentSize.width.isFinite && !contentSize.width.isNaN
            ) ? max(0, contentSize.width) : 0
            let contentH = (
                contentSize.height.isFinite && !contentSize.height.isNaN
            ) ? max(0, contentSize.height) : 0
            // 縦オフセット比（以前のロジックに復元）
            let ratioPortraitRaw = (
                moonPortraitYOffsetRatio.isFinite && !moonPortraitYOffsetRatio.isNaN
            ) ? moonPortraitYOffsetRatio : 0
            let ratioLandscapeRaw = (
                moonLandscapeYOffsetRatio.isFinite && !moonLandscapeYOffsetRatio.isNaN
            ) ? moonLandscapeYOffsetRatio : 0
            let ratioPortrait = max(-1, min(ratioPortraitRaw, 1))
            let ratioLandscape = max(-1, min(ratioLandscapeRaw, 1))
            let margin = max(0, (landscapeMargin.isFinite && !landscapeMargin.isNaN) ? landscapeMargin : 0)

            // 動的サイズ計算（副作用なし）
            let baseMoonSize = max(0, min(contentW, contentH) * 0.5)
            let moonSize = max(120, min(baseMoonSize, 400))
            let timerHeight = max(0, moonSize / 3)
            let timerSpacing = max(0, min(moonSize * 0.5, 120))

            let setHeight = max(0, moonSize + timerSpacing + timerHeight)
            // 子に渡す正規化済み値
            let childW = max(1, contentW)
            let childH = max(1, contentH)
            let childSize = CGSize(width: childW, height: childH)
            let childInsets = EdgeInsets(
                top: (
                    geo2.safeAreaInsets.top.isFinite &&
                    !geo2.safeAreaInsets.top.isNaN
                )
                    ? max(0, geo2.safeAreaInsets.top)
                    : 0,
                leading: (
                    geo2.safeAreaInsets.leading.isFinite &&
                    !geo2.safeAreaInsets.leading.isNaN
                )
                    ? max(0, geo2.safeAreaInsets.leading)
                    : 0,
                bottom: (
                    geo2.safeAreaInsets.bottom.isFinite &&
                    !geo2.safeAreaInsets.bottom.isNaN
                )
                    ? max(0, geo2.safeAreaInsets.bottom)
                    : 0,
                trailing: (
                    geo2.safeAreaInsets.trailing.isFinite &&
                    !geo2.safeAreaInsets.trailing.isNaN
                )
                    ? max(0, geo2.safeAreaInsets.trailing)
                    : 0
            )
            // 画面中央Y（safe area考慮）をオフセットに変換（以前のロジックに復元）
            let centerY = (contentH - safeTop - safeBottom) / 2 + safeTop
            let setCenterYRaw: CGFloat = isLandscape
                ? centerY - contentH * ratioLandscape
                : centerY - contentH * ratioPortrait
            // 横向きでのQuiet Moon表示時は、より中央寄りの位置に調整
            let setCenterYOffset = timerVM.isSessionFinished && isLandscape
                ? -(max(-contentH, min(setCenterYRaw - contentH / 2 + contentH * 0.1, contentH)))
                : -(max(-contentH, min(setCenterYRaw - contentH / 2, contentH)))

            // 横向き時の安全な左パディング（ノッチやホームインジケータ回避）
            let safeLeft = (
                geo2.safeAreaInsets.leading.isFinite && !geo2.safeAreaInsets.leading.isNaN
            ) ? geo2.safeAreaInsets.leading : 0
            let safeRight = (
                geo2.safeAreaInsets.trailing.isFinite && !geo2.safeAreaInsets.trailing.isNaN
            ) ? geo2.safeAreaInsets.trailing : 0
            let usableW = max(1, contentW - (isLandscape ? (safeLeft + safeRight) : 0))
            let effectiveW = isLandscape ? usableW : contentW
            let safeMargin2 = min(margin, effectiveW * 0.8)
            // 双方を少し中央へ寄せるための微小オフセット（機種に依らず控えめに）
            let centerPull = isLandscape ? min(40, effectiveW * 0.05) : 0

            // 完了表示は「完了フラグ かつ 実行中でない（runState / isRunning のどちらでも）」。
            // 実行中シグナルが一瞬でも立てば、確実に進行中画面を優先する。
            let isActivelyRunning = (timerVM.runState == .running) || timerVM.isRunning
            if timerVM.isSessionFinished && !isActivelyRunning {
                // 終了時はQuietMoonViewのみ
                if isLandscape {
                    // 横画面：左右分割（最高品質版）
                    HStack(spacing: safeMargin2) {
                        // 左側：QuietMoonView
                        QuietMoonView(
                            size: childSize,
                            safeAreaInsets: childInsets,
                            isAnimationActive: isMoonAnimationActive,
                            message: timerVM.quietMoonMessage ?? MoonMessage.fallback()
                        )
                        .frame(
                            width: max(1, max(effectiveW - safeMargin2, 0) * 0.5),
                            height: max(1, setHeight)
                        )
                        .background(Color.clear)
                        .zIndex(10)
                        .layoutPriority(1)
                        .offset(x: centerPull)
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
                                startTime: timerVM.startTime,
                                endTime: timerVM.endTime,
                                actualSessionMinutes: timerVM.actualSessionMinutes,
                                onEdit: { showingEditRecord = true }
                            )
                            // Final time の更新で確実に再構築させる（分表示も含めて）
                            .id(
                                "recorded-\(Int(timerVM.endTime?.timeIntervalSince1970 ?? 0))-" +
                                "\(timerVM.actualSessionMinutes)"
                            )
                            .sessionVisibility(isVisible: timerVM.hasRecordedEndTime)
                            .sessionEndTransition(timerVM)
                            Spacer()
                        }
                        .frame(
                            width: max(1, max(effectiveW - safeMargin2, 0) * 0.5),
                            height: max(1, setHeight)
                        )
                        .background(Color.clear)
                        .zIndex(10)
                        .layoutPriority(0)
                        .offset(x: -centerPull)
                        .accessibilityLabel("Session Record")
                        .accessibilityHint(
                            "Shows start time, end time, and session " +
                            "duration"
                        )
                    }
                    .frame(width: usableW, height: max(1, setHeight), alignment: .center)
                    .padding(.leading, isLandscape ? safeLeft : 0)
                    .offset(y: setCenterYOffset)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                } else {
                    // 縦画面：QuietMoonのみ（RecordedTimesはContentView側で重ねる）
                    VStack {
                        QuietMoonView(
                            size: childSize,
                            safeAreaInsets: childInsets,
                            isAnimationActive: isMoonAnimationActive,
                            message: timerVM.quietMoonMessage ?? MoonMessage.fallback()
                        )
                        .accessibilityLabel("Quiet Moon Message")
                        .accessibilityHint(
                            "Displays inspirational messages after session completion"
                        )
                        .accessibilityAddTraits(AccessibilityTraits.isHeader)
                        .focused(isQuietMoonFocused)
                    }
                    .frame(width: max(1, contentW), height: max(1, setHeight), alignment: .center)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .offset(y: -(contentH * ratioPortrait))
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            } else {
                // 進行中はMoon+Timerセット
                if isLandscape {
                    // --- Landscape の Moon + Timer 横並び ---
                    let hStackWidth = max(1, effectiveW)
                    HStack(spacing: safeMargin2) {
                        // MoonView
                        MoonView(
                            moonSize: moonSize,
                            glitterText: moonTitle,
                            size: childSize,
                            isAnimationActive: isMoonAnimationActive
                        )
                        .allowsHitTesting(false)
                        .frame(
                            width: max(hStackWidth - safeMargin2, 0) * 0.5,
                            height: moonSize
                        )
                        .layoutPriority(1)
                        .offset(x: centerPull)

                        // TimerPanel
                        VStack {
                            Spacer()
                            TimerPanel()
                                .frame(
                                    minWidth: moonSize,
                                    maxWidth: moonSize * 1.5,
                                    minHeight: timerHeight,
                                    maxHeight: timerHeight
                                )
                            Spacer()
                        }
                        .frame(
                            width: max(hStackWidth - safeMargin2, 0) * 0.5,
                            height: moonSize
                        )
                        .layoutPriority(0)
                        .offset(x: -centerPull)
                    }
                    .frame(width: max(1, effectiveW), height: max(1, moonSize), alignment: .center)
                    .padding(.leading, isLandscape ? safeLeft : 0)
                    .offset(y: setCenterYOffset)
                } else {
                    // 縦画面：従来通り
                    VStack(spacing: timerSpacing) {
                        MoonView(
                            moonSize: moonSize,
                            glitterText: moonTitle,
                            size: childSize,
                            isAnimationActive: isMoonAnimationActive
                        )
                        .allowsHitTesting(false)

                        TimerPanel()
                            .frame(
                                minWidth: moonSize,
                                maxWidth: moonSize * 1.5,
                                minHeight: timerHeight,
                                maxHeight: timerHeight
                            )
                    }
                    .frame(width: max(1, contentW), height: max(1, setHeight), alignment: .center)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .offset(y: -(contentH * ratioPortrait))
                }
            }
        }
        // シート提示は上位（ContentView）から
    }
}

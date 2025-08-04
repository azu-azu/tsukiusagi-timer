import SwiftUI

struct SideMenuView: View {
    @StateObject private var streakManager = StreakManager()

    @Binding var isPresented: Bool
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    // Environment for orientation detection
    @Environment(\.horizontalSizeClass) private var horizontalClass
    @Environment(\.verticalSizeClass) private var verticalClass

    var body: some View {
        GeometryReader { geo in
            let safeAreaInsets = geo.safeAreaInsets
            let size = geo.size
            let isLandscape = isLandscapeOrientation(size: size)

            // 横向き時の調整値 - デバイスサイズに応じて動的調整
            let baseMenuWidth: CGFloat = isLandscape ?
                min(size.width * 0.5, 480) :
                min(size.width * 0.8, 300)
            let leadingOffset: CGFloat = isLandscape ?
                safeAreaInsets.leading + 40 :
                max(safeAreaInsets.leading, 16) // 縦向きでも最低16pxの余白を確保
            // 左端まで表示するためにleadingOffsetの分だけメニュー幅を広げる
            let menuWidth: CGFloat = baseMenuWidth + leadingOffset
            let topPadding: CGFloat = isLandscape ? safeAreaInsets.top + 20 : safeAreaInsets.top + 60
            let sectionSpacing: CGFloat = isLandscape ? 24 : 16
            let itemVerticalPadding: CGFloat = isLandscape ? 16 : 12

        ZStack {
            // 背景オーバーレイ（半透明で暗くする）
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
            }

            // サイドメニュー本体
            HStack(spacing: 0) {
                // メニューコンテンツ - ScrollViewで囲んで横向き時の溢れに対応
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // メニューヘッダー
                        menuHeader(
                            safeAreaInsets: safeAreaInsets,
                            topPadding: topPadding,
                            isLandscape: isLandscape,
                            leadingOffset: leadingOffset
                        )

                        weeklyCalendarSection()

                        // Duration & Session 設定セクション
                        SideMenuDurationView(isPresented: $isPresented)
                            .padding(.leading, leadingOffset + 20)
                            .padding(.trailing, 20)
                            .padding(.top, sectionSpacing)

                        Divider()
                            .background(DesignTokens.MoonColors.surfaceSecondary)
                            .padding(.leading, leadingOffset + 20)
                            .padding(.trailing, 20)
                            .padding(.vertical, sectionSpacing)

                        // メニューアイテム
                        VStack(alignment: .leading, spacing: sectionSpacing) {
                            menuItem(
                                icon: "chart.bar.fill",
                                title: "History",
                                itemVerticalPadding: itemVerticalPadding,
                                destination: AnyView(
                                    HistoryView()
                                )
                            )

                            Divider()
                                .background(DesignTokens.MoonColors.surfaceSecondary)
                                .padding(.top, sectionSpacing)

                            // アプリ情報
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TsukiUsagi Timer")
                                    .font(DesignTokens.Fonts.caption)
                                    .foregroundColor(DesignTokens.MoonColors.textMuted)

                                Text("Version 1.0.0")
                                    .font(DesignTokens.Fonts.caption)
                                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                            }
                            .padding(.top, sectionSpacing)

                            // 横向き時の下部余白を確保
                            if isLandscape {
                                Spacer(minLength: 20)
                            } else {
                                Spacer()
                            }
                        }
                        .padding(.leading, leadingOffset + 20)
                        .padding(.trailing, 20)
                        .padding(.bottom, safeAreaInsets.bottom + 20)
                    }
                }
                .frame(width: menuWidth)
                .frame(maxHeight: .infinity)
                .background(DesignTokens.CosmosColors.background)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .offset(x: isPresented ? 0 : -menuWidth)

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
    }

    @ViewBuilder
    private func menuHeader(
        safeAreaInsets: EdgeInsets,
        topPadding: CGFloat,
        isLandscape: Bool,
        leadingOffset: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: isLandscape ? 8 : 12) {
            HStack {
                Text("🌙")
                    .font(DesignTokens.Fonts.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TsukiUsagi")
                        .font(DesignTokens.Fonts.labelBold)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)

                    Text("Focus Timer")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.leading, leadingOffset + 20)
        .padding(.trailing, 20)
        .padding(.top, topPadding)
        .padding(.bottom, isLandscape ? 12 : 16)
        .background(DesignTokens.CosmosColors.cardBackground)
    }

    @ViewBuilder
    private func menuItem<Destination: View>(
        icon: String,
        title: String,
        itemVerticalPadding: CGFloat,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
            }
            .padding(.vertical, itemVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Functions

    /// 横向き表示かどうかを判定
    private func isLandscapeOrientation(size: CGSize) -> Bool {
        return size.width > size.height
    }

    private func weeklyCalendarSection() -> some View {
        VStack(spacing: 6) {
            Text("Your Weekly Progress")
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(Color.textWhite)

            WeeklyCalendarSectionView(streakManager: streakManager)
        }
        .padding()
        .background(.black)
    }
}

#if DEBUG
// Preview用ダミーサービス
private class PreviewSideMenuDummyEngine: TimerEngineable {
    var timeRemaining: Int = 1500
    var isRunning: Bool = false
    var onTick: ((Int) -> Void)?
    var onSessionCompleted: ((TimerSessionInfo) -> Void)?
    func start(seconds: Int) {}
    func pause() {}
    func resume() {}
    func stop() {}
    func reset(to seconds: Int) {}
}

private class PreviewSideMenuDummyNotification: PhaseNotificationServiceable {
    func sendStartNotification() {}
    func cancelNotification() {}
    func scheduleSessionEndNotification(after seconds: Int, phase: PomodoroPhase) {}
    func sendPhaseChangeNotification(for phase: PomodoroPhase) {}
    func cancelSessionEndNotification() {}
    func finalizeWorkPhase() {}
    func finalizeBreakPhase() {}
}

private class PreviewSideMenuDummyHaptic: HapticServiceable {
    func heavyImpact() {}
    func lightImpact() {}
}

private class PreviewSideMenuDummyHistory: SessionHistoryServiceable {
    func add(parameters: AddSessionParameters) {}
}

private class PreviewSideMenuDummyPersistence: TimerPersistenceManageable {
    var timeRemaining: Int = 1500
    var isRunning: Bool = false
    var isWorkSession: Bool = true
    func saveTimerState() {}
    func restoreTimerState() {}
}

private class PreviewSideMenuDummyFormatter: TimeFormatterUtilable {
    func format(seconds: Int) -> String { "25:00" }
    func format(date: Date?) -> String { "2024-01-01" }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {

        let timerVM = TimerViewModel(
            engine: PreviewSideMenuDummyEngine(),
            notificationService: PreviewSideMenuDummyNotification(),
            hapticService: PreviewSideMenuDummyHaptic(),
            historyService: PreviewSideMenuDummyHistory(),
            persistenceManager: PreviewSideMenuDummyPersistence(),
            formatter: PreviewSideMenuDummyFormatter()
        )

        let historyVM = HistoryViewModel()
        let sessionManager = SessionManager()

        NavigationView {
            ZStack {
                Color.cosmosBackground.ignoresSafeArea()

                SideMenuView(isPresented: .constant(true))
            }
        }
        .environmentObject(timerVM)
        .environmentObject(historyVM)
        .environmentObject(sessionManager)
        .previewInterfaceOrientation(.landscapeLeft) // 横向きプレビュー用
    }
}
#endif

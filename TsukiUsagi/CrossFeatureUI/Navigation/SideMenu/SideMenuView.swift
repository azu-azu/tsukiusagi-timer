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

    // MARK: - Layout Constants

    /// サイドメニューの内部パディング（左右）
    /// Weekly progress カードの外側マージン(16)に合わせる
    static let menuHorizontalPadding: CGFloat = 16

    /// メニューを完全に隠すための追加オフセット
    static let menuHideOffset: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let safeAreaInsets = geo.safeAreaInsets
            let size = geo.size
            let isLandscape = isLandscapeOrientation(size: size)

            // 横向き時の調整値 - デバイスサイズに応じて動的調整
            let baseMenuWidth: CGFloat = isLandscape ?
                min(size.width * 0.5, 480) :
                min(size.width * 0.8, 300)
            let minLeading: CGFloat = isLandscape ? 40 : 16
            let leadingOffset: CGFloat = max(safeAreaInsets.leading, minLeading)
            // 安全な表示幅（左のセーフエリア分はパディングで確保する）
            let menuWidth: CGFloat = baseMenuWidth
            let effectiveMenuWidth: CGFloat = menuWidth + leadingOffset + SideMenuView.menuHorizontalPadding
            let topPadding: CGFloat = isLandscape ? safeAreaInsets.top + 20 : safeAreaInsets.top + 60
            let sectionSpacing: CGFloat = isLandscape ? 24 : 16
            let itemVerticalPadding: CGFloat = isLandscape ? 16 : 12

        ZStack {
            // 背景オーバーレイ（半透明で暗くする）
            if isPresented {
                DesignTokens.CosmosColors.background.opacity(0.3)
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
                            .sideMenuPadding(leadingOffset: leadingOffset)
                            .padding(.top, sectionSpacing)

                        Divider()
                            .background(DesignTokens.CosmosColors.cardBackground)
                            .sideMenuPadding(leadingOffset: leadingOffset)
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
                                .background(DesignTokens.CosmosColors.cardBackground)
                                .padding(.top, sectionSpacing)

                            // アプリ情報
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TsukiUsagi Timer")
                                    .appInfoStyle()

                                Text("Version 1.0.0")
                                    .appInfoStyle()
                            }
                            .padding(.top, sectionSpacing)

                            // 横向き時の下部余白を確保
                            if isLandscape {
                                Spacer(minLength: 20)
                            } else {
                                Spacer()
                            }
                        }
                        .sideMenuPadding(leadingOffset: leadingOffset)
                        .padding(.bottom, safeAreaInsets.bottom + 20)
                    }
                }
                .frame(width: menuWidth)
                .padding(.leading, leadingOffset + SideMenuView.menuHorizontalPadding)
                .frame(maxHeight: .infinity)
                // .background(Color(red: 0.0, green: 0.1, blue: 0.2).opacity(0.9))
                .background(DesignTokens.CosmosColors.background.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: DesignTokens.BlackColors.primary.opacity(0.4), radius: 8, x: -4, y: 0)
                .shadow(color: DesignTokens.BlackColors.primary.opacity(0.4), radius: 8, x: 4, y: 0)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .offset(x: isPresented ? 0 : -effectiveMenuWidth - Self.menuHideOffset)

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
                        .titleStyle()

                    Text("Focus Timer")
                        .subtitleStyle()
                }

                Spacer()
            }
        }
        .sideMenuPadding(leadingOffset: leadingOffset)
        .padding(.top, topPadding)
        .padding(.bottom, isLandscape ? 12 : 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [DesignTokens.CosmosColors.background, DesignTokens.CosmosColors.background.opacity(0.95)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
        WeeklyCalendarSectionView(streakManager: streakManager)
    }
}

// MARK: - View Extensions

private extension View {
    /// サイドメニューの標準水平パディングを適用
    func sideMenuPadding(leadingOffset: CGFloat) -> some View {
        self
            // メニュー幅に leadingOffset を含めているため、パディングは固定値のみ適用
            .padding(.leading, SideMenuView.menuHorizontalPadding)
            .padding(.trailing, SideMenuView.menuHorizontalPadding)
    }
}

// MARK: - Text Style Extensions

private extension Text {
    /// キャプション + ミュートテキストのスタイル（アプリ情報用）
    func appInfoStyle() -> some View {
        self
            .font(DesignTokens.Fonts.caption)
            .foregroundColor(DesignTokens.MoonColors.textMuted)
    }

    /// ラベル太字 + プライマリテキストのスタイル（タイトル用）
    func titleStyle() -> some View {
        self
            .font(DesignTokens.Fonts.labelBold)
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
    }

    /// キャプション + セカンダリテキストのスタイル（サブタイトル用）
    func subtitleStyle() -> some View {
        self
            .font(DesignTokens.Fonts.caption)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
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
    var runStateRaw: String? = nil
    var endAtEpoch: Double? = nil
    var remainingAtPause: Int? = nil
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
                DesignTokens.CosmosColors.background.ignoresSafeArea()

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

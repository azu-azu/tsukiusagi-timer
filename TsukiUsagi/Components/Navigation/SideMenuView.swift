import SwiftUI

struct SideMenuView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var timerVM: TimerViewModel
    @EnvironmentObject private var historyVM: HistoryViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    
    private let menuWidth: CGFloat = 300
    
    var body: some View {
        GeometryReader { geo in
            let safeAreaInsets = geo.safeAreaInsets
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
                // メニューコンテンツ
                VStack(alignment: .leading, spacing: 0) {
                    // メニューヘッダー
                    menuHeader(safeAreaInsets: safeAreaInsets)
                    
                    // メニューアイテム
                    VStack(alignment: .leading, spacing: 16) {
                        menuItem(
                            icon: "gearshape.fill",
                            title: "Settings",
                            destination: AnyView(
                                SettingsView(
                                    size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
                                    safeAreaInsets: EdgeInsets(
                                        top: safeAreaInsets.top,
                                        leading: safeAreaInsets.leading,
                                        bottom: safeAreaInsets.bottom,
                                        trailing: safeAreaInsets.trailing
                                    )
                                )
                                .environmentObject(timerVM)
                                .environmentObject(historyVM)
                                .environmentObject(sessionManager)
                            )
                        )
                        
                        menuItem(
                            icon: "chart.bar.fill",
                            title: "History",
                            destination: AnyView(
                                HistoryView()
                                .environmentObject(historyVM)
                            )
                        )
                        
                        Divider()
                            .background(DesignTokens.MoonColors.surfaceSecondary)
                        
                        // アプリ情報
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TsukiUsagi Timer")
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.MoonColors.textMuted)
                            
                            Text("Version 1.0.0")
                                .font(DesignTokens.Fonts.caption)
                                .foregroundColor(DesignTokens.MoonColors.textMuted)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, safeAreaInsets.top + 40)
                }
                .frame(width: menuWidth)
                .frame(maxHeight: .infinity)
                .background(DesignTokens.CosmosColors.background)
                .offset(x: isPresented ? 0 : -menuWidth)
                
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
    }
    
    @ViewBuilder
    private func menuHeader(safeAreaInsets: EdgeInsets) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🌙")
                    .font(.system(size: 32))
                
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
        .padding(.horizontal, 20)
        .padding(.top, safeAreaInsets.top + 60)
        .padding(.bottom, 16)
        .background(DesignTokens.CosmosColors.cardBackground)
    }
    
    @ViewBuilder
    private func menuItem<Destination: View>(
        icon: String,
        title: String,
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
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        })
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
    }
}
#endif
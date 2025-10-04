import SwiftUI
import Foundation

extension ContentView {
    // MARK: - Footer Components

    struct FooterLayerParams {
        let safeAreaInsets: EdgeInsets
        let buttonHeight: CGFloat
        let buttonWidth: CGFloat
        let today: Date
        let isRunning: Bool
        let isSessionFinished: Bool
        let showingSideMenu: Binding<Bool>
        let onPause: () -> Void
        let onStart: () -> Void
    }

    @ViewBuilder
    func footerLayer(params: FooterLayerParams) -> some View {
        // footerBarはZStackの一番下（ギアボタンと日付を削除）
        FooterBar(
            buttonHeight: params.buttonHeight,
            buttonWidth: params.buttonWidth,
            dateString: "", // 日付表示を削除
            onGearTap: nil, // ギアボタンを無効化
            startPauseButton: startPauseButton(params: StartPauseButtonParams(
                buttonWidth: params.buttonWidth,
                buttonHeight: params.buttonHeight,
                isRunning: params.isRunning,
                isSessionFinished: params.isSessionFinished,
                onPause: { params.onPause() },
                onStart: { params.onStart() }
            ))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, params.safeAreaInsets.bottom)
        .zIndex(2010) // SideMenuViewより高く設定してタップ可能にする
        .onAppear {
        }

        // ギアボタン（左下）と日付表示（右下）
        VStack {
            Spacer()
            HStack {
                // ギアボタン（左下）
                SettingsMenuButton(action: {
                    HapticManager.shared.buttonTapFeedback()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        params.showingSideMenu.wrappedValue.toggle()
                    }
                })
                .padding(.leading, 16)
                .padding(.bottom, params.safeAreaInsets.bottom)

                Spacer()
                // 日付表示（右下）
                Text(DateFormatters.displayDateNoYear.string(from: params.today))
                    .font(DesignTokens.Fonts.footerDate)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                    .padding(.trailing, 16)
                    .padding(.bottom, params.safeAreaInsets.bottom)
            }
        }
        .zIndex(2010) // SideMenuViewより高く設定してタップ可能にする
    }


    // MARK: - Button Components

    struct StartPauseButtonParams {
        let buttonWidth: CGFloat
        let buttonHeight: CGFloat
        let isRunning: Bool
        let isSessionFinished: Bool
        let onPause: () -> Void
        let onStart: () -> Void
    }

    func startPauseButton(params: StartPauseButtonParams) -> some View {
        Button(params.isRunning ? "PAUSE" : "START") {
            
            // セッション完了後でタイマーが実行中の場合のみ無視
            guard !(params.isSessionFinished && params.isRunning) else {
                return
            }
            
            HapticManager.shared.buttonTapFeedback()
            if params.isRunning {
                params.onPause() // PAUSE時はpauseTimer()を使用
            } else {
                params.onStart()
            }
        }
        .frame(width: params.buttonWidth, height: params.buttonHeight)
        .background(Color.white.opacity(params.isSessionFinished ? 0.1 : 0.2),
                    in: RoundedRectangle(cornerRadius: 20))
        .titleWhiteAvenir(weight: .bold)
        .foregroundColor(params.isSessionFinished ? 
                        DesignTokens.PureColors.textWhite.opacity(0.5) : 
                        DesignTokens.PureColors.textWhite)
        .disabled(false) // セッション完了後も新しいセッションを開始できるようにする
        .allowsHitTesting(true)
        .zIndex(2020) // ボタンを最前面に配置
        .onAppear {
        }
    }
}

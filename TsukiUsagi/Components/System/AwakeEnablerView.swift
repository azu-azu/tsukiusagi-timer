import SwiftUI

struct AwakeEnablerView: View {
    // 表示／非表示の切り替えフラグ
    var hidden: Bool = false

    var body: some View {
        VStack {
            Text("タイマー中")
                .font(DesignTokens.Fonts.caption)
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        // 👇 ここで高さゼロ＆クリップ
        .frame(height: hidden ? 0 : nil)
        .clipped()
    }
}

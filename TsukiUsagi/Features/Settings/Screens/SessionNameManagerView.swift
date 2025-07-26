import Foundation
import SwiftUI

struct SessionNameManagerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var errorTitle: String = "Error"
    @State private var isKeyboardVisible: Bool = false

    // 画面を閉じるためのプレゼンテーション用
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 背景（画面全体、clipされない）
            ZStack {
                Color.cosmosBackground.ignoresSafeArea()

                // キーボード表示時は星を非表示
                // if !isKeyboardVisible {
                //     StaticStarsView(starCount: 30)
                //         .allowsHitTesting(false)
                //         .transition(.opacity.animation(.easeInOut(duration: 0.3)))

                //     FlowingStarsView(
                //         starCount: 20,
                //         angle: .degrees(135),
                //         durationRange: 24 ... 40,
                //         sizeRange: 2 ... 4,
                //         spawnArea: nil
                //     )
                //     .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                // }
            }

            // メインコンテンツ
            VStack(spacing: 0) {
                // CommonHeaderViewを使用（追加の上余白付き）
                CommonHeaderView(
                    configuration: HeaderConfiguration(
                        title: "Manage Session Names",
                        leftButton: HeaderButton(
                            title: "Close",
                            action: {
                                dismiss()
                            }
                        ),
                        rightButton: HeaderButton(
                            title: "Done",
                            action: {
                                // 必要に応じて保存処理などを実行
                                dismiss()
                            }
                        )
                    )
                )
                .padding(.top, 8) // 追加の上余白

                // コンテンツエリア
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        NewSessionFormView()
                        // --- ここから登録済みセッションの明示的な表示 ---
                        SessionListSectionView()
                        // --- ここまで ---
                    }
                    .padding()
                }
                .dismissKeyboardOnTap()
            }
        }
        .debugScreen(String(describing: Self.self))
        .navigationBarHidden(true) // ナビゲーションバーを非表示にしてCommonHeaderViewを使用
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = false
            }
        }
        .task {
            // sessionManager.loadAsync() など旧API呼び出しをすべて削除
            await MainActor.run {
                print("✅ Load success. Entries count: \(sessionManager.allEntries.count)")
                for session in sessionManager.allEntries {
                    print("📝 Session: \(session.sessionName)")
                }
                // 成功時アラートは表示しない
            }
        }
    }
}

#if DEBUG
    struct SessionNameManagerView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                SessionNameManagerView()
                    .environmentObject(SessionManager.previewData)
            }
        }
    }
#endif

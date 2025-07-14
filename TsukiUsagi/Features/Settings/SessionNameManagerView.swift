import Foundation
import SwiftUI

struct SessionNameManagerView: View {
    @EnvironmentObject var sessionManager: SessionManagerV2
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var errorTitle: String = "Error"
    @State private var isKeyboardVisible: Bool = false

    var body: some View {
        ZStack {
            // 背景（画面全体、clipされない）
            ZStack {
                Color.moonBackground.ignoresSafeArea()

                // キーボード表示時は星を非表示
                if !isKeyboardVisible {
                    StaticStarsView(starCount: 30)
                        .allowsHitTesting(false)
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))

                    FlowingStarsView(
                        starCount: 20,
                        angle: .degrees(135),
                        durationRange: 24 ... 40,
                        sizeRange: 2 ... 4,
                        spawnArea: nil
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }
            }

            // コンテンツ
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                    HiddenKeyboardWarmer() // ← 追加
                    NewSessionFormView()
                    // --- ここから登録済みセッションの明示的な表示 ---
                    List {
                        // デバッグ用: セッション数表示
                        Text("Total sessions: \(sessionManager.sessions.count)")
                            .foregroundColor(.red)
                        ForEach(sessionManager.sessions) { session in
                            SessionRowView(
                                session: session,
                                // 必要なBindingやコールバックは適宜渡す
                                editingId: .constant(nil),
                                editingName: .constant(""),
                                editingSubtitles: .constant([""]),
                                showDeleteAlert: .constant(nil),
                                saveEdit: { _ in },
                                deleteSession: { _ in }
                            )
                        }
                    }
                    .frame(maxHeight: 300) // スクロール内で高さ制限（必要に応じて調整）
                    .background(Color.white)
                    // --- ここまで ---
                }
                .padding()
            }
            .scrollIndicators(.hidden) // スクロールインジケーター非表示
            .scrollDismissesKeyboard(.interactively) // キーボード制御を改善
        }
        .navigationTitle("Manage Session Names")
        .navigationBarTitleDisplayMode(.large)
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
            do {
                try await sessionManager.loadAsync()
                await MainActor.run {
                    print("✅ Load success. Sessions count: \(sessionManager.sessions.count)")
                    for session in sessionManager.sessions {
                        print("📝 Session: \(session.name)")
                    }
                    // 成功時アラートは表示しない
                }
            } catch {
                await MainActor.run {
                    print("❌ Load failed: \(error)")
                    errorTitle = "Failed to Load Sessions"
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#if DEBUG
    struct SessionNameManagerView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                SessionNameManagerView()
                    .environmentObject(SessionManagerV2.previewData)
            }
        }
    }
#endif

import Foundation
import SwiftUI

struct SessionNameManagerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var errorTitle: String = "Error"
    @State private var isKeyboardVisible: Bool = false

    var body: some View {
        ScrollView {
            RoundedCard(backgroundColor: DesignTokens.CosmosColors.cardBackground) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                    NewSessionFormView()
                    // --- ここから登録済みセッションの明示的な表示 ---
                    SessionListSectionView()
                    // --- ここまで ---
                }
            }
            .padding()
        }
        .dismissKeyboardOnTap()
        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
        .navigationTitle("Manage Session Names")
        .navigationBarTitleDisplayMode(.inline)
        .debugScreen(String(describing: Self.self))
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

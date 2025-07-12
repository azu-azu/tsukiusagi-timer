import SwiftUI

struct SessionNameManagerView: View {
    @EnvironmentObject var sessionManager: SessionManagerV2
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var errorTitle: String = "Error"

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
            NewSessionFormView()
            SessionListSectionView()
        }
        .padding()
        .navigationTitle("Manage Session Names")
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .adaptiveStarBackground()
        .task {
            do {
                try await sessionManager.loadAsync()
            } catch {
                errorTitle = "Failed to Load Sessions"
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#if DEBUG
struct SessionNameManagerView_Previews: PreviewProvider {
    static var previews: some View {
        SessionNameManagerView()
            .environmentObject(SessionManagerV2())
    }
}
#endif

import SwiftUI

struct SettingsHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("activityLabel") private var activityLabel: String = "Work"

    // ヘッダー周りのpadding
    private let headerTopPadding: CGFloat = 5
    private let headerBottomPadding: CGFloat = 34

    private var isCustomActivity: Bool {
        !["Work", "Study", "Read"].contains(activityLabel)
    }

    // バリデーション関数の共通化
    private func isActivityEmpty() -> Bool {
        return activityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldDisableDone() -> Bool {
        return isCustomActivity && isActivityEmpty()
    }

    var body: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(DesignTokens.Colors.moonTextSecondary)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .disabled(shouldDisableDone())
            .foregroundColor(
                shouldDisableDone()
                    ? .gray
                    : DesignTokens.Colors.moonAccentBlue
            )
        }
        .padding(.horizontal)
        .padding(.top, headerTopPadding)
        .padding(.bottom, headerBottomPadding)
    }
}

#if DEBUG
struct SettingsHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsHeaderView()
    }
}
#endif
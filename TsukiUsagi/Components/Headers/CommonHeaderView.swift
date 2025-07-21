import SwiftUI

// MARK: - 共通ヘッダービュー
struct CommonHeaderView: View {
    private let configuration: HeaderConfiguration

    // ヘッダー周りのpadding（SettingsViewの構造に合わせて調整）
    private let headerTopPadding: CGFloat = 8   // SettingsViewの余白に合わせて減らす
    private let headerBottomPadding: CGFloat = 20

    init(configuration: HeaderConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        HStack {
            // 左ボタン
            if let leftButton = configuration.leftButton {
                Button(leftButton.title) {
                    leftButton.action()
                }
                .foregroundColor(leftButton.color)
                .disabled(leftButton.isDisabled)
            } else {
                // 左ボタンがない場合、スペーサーでバランスを取る
                Spacer()
                    .frame(maxWidth: 60) // 適当な幅でバランス調整
            }

            Spacer()

            Text(configuration.title)
                .font(DesignTokens.Fonts.labelBold)
                .foregroundColor(.moonTextPrimary)

            Spacer()

            // 右ボタン
            if let rightButton = configuration.rightButton {
                Button(rightButton.title) {
                    rightButton.action()
                }
                .foregroundColor(rightButton.color)
                .disabled(rightButton.isDisabled)
            } else {
                // 右ボタンがない場合、スペーサーでバランスを取る
                Spacer()
                    .frame(maxWidth: 60) // 適当な幅でバランス調整
            }
        }
        .padding(.horizontal)
        .padding(.top, headerTopPadding)
        .padding(.bottom, headerBottomPadding)
    }
}

// MARK: - プレビュー
#if DEBUG
struct CommonHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 標準的なClose/Doneパターン
            CommonHeaderView(
                configuration: .closeDone(
                    title: "Settings",
                    onDone: { print("Done tapped") }
                )
            )

            Divider()

            // Cancel/Saveパターン
            CommonHeaderView(
                configuration: .cancelSave(
                    title: "Edit Record",
                    onSave: { print("Save tapped") }
                )
            )

            Divider()

            // 右ボタンのみの例
            CommonHeaderView(
                configuration: .rightButtonOnly(
                    title: "View Only",
                    rightButtonTitle: "Edit",
                    rightButtonAction: { print("Edit tapped") }
                )
            )

            Divider()

            // 削除アクションの例
            CommonHeaderView(
                configuration: HeaderConfiguration(
                    title: "Delete Item",
                    leftButton: HeaderButton(
                        title: "Cancel",
                        action: { print("Cancel") },
                        role: .cancel
                    ),
                    rightButton: HeaderButton(
                        title: "Delete",
                        action: { print("Delete") },
                        role: .destructive
                    )
                )
            )

            Spacer()
        }
        .background(Color.cosmosBackground)
    }
}
#endif

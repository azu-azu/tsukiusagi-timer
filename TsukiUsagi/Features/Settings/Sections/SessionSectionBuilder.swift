import SwiftUI

/// セクション表示専用コンポーネント
///
/// 責務：
/// - Default/Custom セクションの表示
/// - セッション一覧の表示
/// - 基本的なアクションの委譲
struct SessionSectionBuilder: View {
    let title: String
    let entries: [SessionEntry]
    let isDefault: Bool
    let onEditSession: (SessionEntry) -> Void
    let onDeleteSession: (SessionEntry) -> Void
    let onEditDescription: (SessionEntry, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader
            sectionContent
        }
        .onTapGesture {
            // 空の部分をタップしたらキーボードを閉じる
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Private Views

    private var sectionHeader: some View {
        Text(title)
            .font(DesignTokens.Fonts.sectionTitle)
            .foregroundColor(DesignTokens.MoonColors.textPrimary)
            .padding(.horizontal)
    }

    private var sectionContent: some View {
        Group {
            if entries.isEmpty {
                emptyStateView
            } else {
                sessionList
            }
        }
    }

    private var emptyStateView: some View {
        Text(isDefault ? "No default sessions." : "No custom sessions. Tap + to add.")
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
            .italic()
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    private var sessionList: some View {
        VStack(spacing: 4) {
            ForEach(entries) { entry in
                SessionRowComponent(
                    entry: entry,
                    isDefault: isDefault,
                    onEdit: { onEditSession(entry) },
                    onDelete: { onDeleteSession(entry) },
                    onEditDescription: { index in onEditDescription(entry, index) }
                )
                .allowsHitTesting(true) // 明示的にタッチイベントを許可
            }
        }
        .padding(.horizontal)
        .contentShape(Rectangle()) // タッチ領域を明確に定義
        .onTapGesture {
            // セッション一覧の空の部分をタップしたらキーボードを閉じる
            hideKeyboard()
        }
    }
}

/// セッション行表示コンポーネント
///
/// 責務：
/// - 個別セッションの表示
/// - デフォルト/カスタムセッションの見た目切り替え
/// - アクションボタンの表示
struct SessionRowComponent: View {
    let entry: SessionEntry
    let isDefault: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onEditDescription: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            sessionHeader
            sessionDescriptions
        }
        .padding()
        .background(sessionBackground)
        .contentShape(Rectangle()) // タッチ領域を明確に定義
        .onTapGesture {
            // セッション行の空の部分をタップしたらキーボードを閉じる
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Private Views

    private var sessionHeader: some View {
        HStack(alignment: .top) {
            Text(entry.sessionName)
                .font(.body)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            Spacer()
            if !isDefault {
                actionButtons
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Edit", action: onEdit)
                .buttonStyle(.bordered)

            Button(
                role: .destructive,
                action: onDelete,
                label: {
                    Image(systemName: "trash")
                }
            )
            .buttonStyle(.bordered)
        }
    }

    private var sessionDescriptions: some View {
        Group {
            if !entry.descriptions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(entry.descriptions.enumerated()), id: \.offset) { index, description in
                        if isDefault {
                            editableDescriptionRow(description: description, index: index)
                        } else {
                            displayDescriptionRow(description: description)
                        }
                    }
                }
            }
        }
    }

    private func editableDescriptionRow(description: String, index: Int) -> some View {
        HStack {
            Text(description)
                .font(.subheadline)
                .italic()
                .foregroundColor(.white.opacity(0.6))
                .padding(.leading, 16)

            Spacer()

            Image(systemName: "pencil")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
                .padding(.trailing, 8)
        }
        .padding(.vertical, 6)
        .background(editableRowBackground)
        .contentShape(Rectangle())
        .accessibilityLabel("Edit description: \(description)")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onEditDescription(index)
        }
        .simultaneousGesture(
            // 編集用のタップと同時に実行される場合のハンドリング
            TapGesture()
                .onEnded { _ in
                    // 編集開始時は他のキーボードを閉じる
                    hideKeyboard()
                }
        )
    }

    private func displayDescriptionRow(description: String) -> some View {
        Text(description)
            .font(.subheadline)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
            .padding(.leading, 16)
    }

    private var editableRowBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
            .background(Color.white.opacity(0.02))
    }

    private var sessionBackground: some View {
        Group {
            if !isDefault {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.02))
            }
        }
    }
}

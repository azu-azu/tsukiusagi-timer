import SwiftUI

struct SessionDescriptionsView: View {
    @Binding var editingName: String
    @Binding var editingDescriptions: [String]
    @FocusState.Binding var isSubtitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            descriptionHeaderView
            descriptionListView
            addDescriptionButtonView
        }
    }

    // Description ヘッダー
    private var descriptionHeaderView: some View {
        HStack {
            Text("Descriptions")
                .font(.caption)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            if !editingName.isEmpty {
                Text("for \"\(editingName)\"")
                    .font(.caption)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
            }
        }
    }

    // Description リスト
    private var descriptionListView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(editingDescriptions.indices, id: \.self) { idx in
                descriptionRowView(at: idx)
            }
        }
    }

    // Description 行
    private func descriptionRowView(at idx: Int) -> some View {
        HStack {
            // インデント表現
            Rectangle()
                .fill(Color.clear)
                .frame(width: 16, height: 1)

            TextField("Description \(idx + 1)", text: Binding(
                get: { editingDescriptions[safe: idx] ?? "" },
                set: { newValue in
                    if idx < editingDescriptions.count {
                        editingDescriptions[idx] = newValue
                    }
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .accessibilityIdentifier(AccessibilityIDs.SessionManager.descriptionField)
            .focused($isSubtitleFocused)
            .onChange(of: isSubtitleFocused) {
                // Focus handling
            }

            Button(action: { editingDescriptions.remove(at: idx) }, label: {
                Image(systemName: "minus.circle")
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
            })
            .buttonStyle(.plain)
            .disabled(editingDescriptions.count == 1)
        }
    }

    // Add Description ボタン
    private var addDescriptionButtonView: some View {
        HStack {
            // インデント表現
            Rectangle()
                .fill(Color.clear)
                .frame(width: 16, height: 1)

            Button(action: { editingDescriptions.append("") }, label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Add Subtitle")
                }
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            })
            .font(DesignTokens.Fonts.caption)
            .buttonStyle(.plain)
            .disabled(
                editingName.isEmpty ||
                (
                    editingDescriptions.first?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty ?? true
                )
            )

            Spacer()
        }
    }
}

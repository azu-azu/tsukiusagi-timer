import SwiftUI

/// Reflection入力セクション（共通コンポーネント）
/// DailyTimelineViewとEditRecordViewで共有
struct ReflectionInputSection: View {
    let text: String
    let isEditing: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Labels.Sections.reflection)
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.SkyToneColors.textPrimary)

            EditablePlaceholderCard(
                text: text,
                placeholder: LocalizedStringKey("reflection_placeholder"),
                isEditing: isEditing,
                onTap: onTap
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

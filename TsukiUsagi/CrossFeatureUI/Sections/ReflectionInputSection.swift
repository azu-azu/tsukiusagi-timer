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

            ReflectionInputCard(
                text: text,
                isEditing: isEditing,
                onTap: onTap
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Reflection専用のインセット風入力カード
/// 角丸なし、暗めの背景で「書き込む場所」を表現
private struct ReflectionInputCard: View {
    let text: String
    let isEditing: Bool
    let onTap: () -> Void

    private let placeholder: LocalizedStringKey = "reflection_placeholder"

    var body: some View {
        let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        Button(action: onTap) {
            ZStack {
                // 通常コンテンツ
                HStack {
                    if isEmpty {
                        Text(placeholder)
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.SkyToneColors.textQuinary)
                    } else {
                        Text(text)
                            .font(DesignTokens.Fonts.label)
                            .foregroundColor(DesignTokens.SkyToneColors.textPrimary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .opacity(isEditing ? 0 : 1)

                // 編集中インジケータ
                if isEditing {
                    HStack(spacing: 6) {
                        PencilIcon(size: .small)
                        Text("editing_below")
                            .font(DesignTokens.Fonts.caption)
                            .foregroundColor(DesignTokens.SkyToneColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isEmpty ? 12 : 16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(DesignTokens.SkyToneColors.cardGradient)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isEditing ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .allowsHitTesting(!isEditing)
    }
}

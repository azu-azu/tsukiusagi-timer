import SwiftUI

// MARK: - Row Labels

extension SessionManagementView {
    @ViewBuilder
    func defaultRowLabel(session: SessionEntry) -> some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            Image(systemName: session.iconName)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolMedium)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                Text(session.sessionName)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Text("\(session.tasks.count) tasks")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
            }

            Spacer()

            PencilIcon(size: .small)
        }
        .padding(.horizontal, DesignTokens.Padding.cardHorizontal)
        .padding(.vertical, DesignTokens.Padding.medium)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    func customRowLabel(session: SessionEntry) -> some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            Image(systemName: session.iconName)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolMedium)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                Text(session.sessionName)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                if let task = session.tasks.first, !task.isEmpty {
                    Text(task)
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolSmall)
        }
        .padding(.horizontal, DesignTokens.Padding.cardHorizontal)
        .padding(.vertical, DesignTokens.Padding.medium)
        .contentShape(Rectangle())
    }
}

// MARK: - SessionEntry UI Extension

extension SessionEntry {
    var iconName: String {
        switch sessionName.lowercased() {
        case "work":
            return "briefcase.fill"
        case "study":
            return "book.fill"
        case "read":
            return "text.book.closed.fill"
        default:
            return "folder.fill"
        }
    }
}

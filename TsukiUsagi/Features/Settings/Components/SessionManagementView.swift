import SwiftUI

struct SessionManagementView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSession: SessionEntry?
    @State private var showDeleteConfirm: Bool = false

    private enum ActiveSheet: Identifiable {
        case edit(SessionEntry)
        case create

        var id: String {
            switch self {
            case .edit(let session):
                return "edit-\(session.id.uuidString)"
            case .create:
                return "create"
            }
        }
    }

    @State private var activeSheet: ActiveSheet?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    Text(NSLocalizedString("session_management_title", comment: ""))
                        .font(DesignTokens.Fonts.title)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)

                    Text(NSLocalizedString("session_management_subtitle", comment: ""))
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                }

                // Default Sessions Section (Description editing only)
                defaultSessionsSection()

                // Custom Sessions Section (Full CRUD)
                customSessionsSection()
            }
            .padding(.horizontal, DesignTokens.Padding.large)
            .padding(.top, DesignTokens.Padding.large)
            .padding(.bottom, DesignTokens.Padding.extraLarge)
        }
        .safeAreaInset(edge: .bottom) {
            addCustomSessionButton()
                .padding(.horizontal, DesignTokens.Padding.large)
                .padding(.bottom, DesignTokens.Padding.large)
                .background(.clear)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit(let session):
                SessionEditView(session: session)
            case .create:
                CreateCustomSessionView()
            }
        }
        .alert("Delete Session", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let session = selectedSession, !session.isDefault {
                    sessionManager.deleteEntry(id: session.id)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let session = selectedSession {
                Text("Are you sure you want to delete '\(session.sessionName)'?")
            }
        }
        .navigationTitle("Session Management")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Default Sessions Section

    @ViewBuilder
    private func defaultSessionsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            defaultSessionsHeader()
            defaultSessionsList()
        }
    }

    @ViewBuilder
    private func defaultSessionsHeader() -> some View {
        Text(NSLocalizedString("default_sessions_title", comment: ""))
            .font(DesignTokens.Fonts.sectionTitle)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
    }

    @ViewBuilder
    private func defaultSessionsList() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sessionManager.defaultEntries.enumerated()), id: \.element.id) { index, session in
                defaultSessionRow(session, isLast: index == sessionManager.defaultEntries.count - 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .stroke(DesignTokens.BlackColors.stroke.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func defaultSessionRow(_ session: SessionEntry, isLast: Bool) -> some View {
        Button {
            selectedSession = session
            activeSheet = .edit(session)
        } label: { defaultRowLabel(session: session) }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                selectedSession = session
                activeSheet = .edit(session)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(DesignTokens.MoonColors.accentBlue)
        }

        if !isLast {
            Divider()
                .padding(.leading, DesignTokens.Padding.large + 20 + DesignTokens.Spacing.large)
        }
    }

    // MARK: - Custom Sessions Section

    @ViewBuilder
    private func customSessionsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            customSessionsHeader()
            customSessionsList()
        }
    }

    @ViewBuilder
    private func customSessionsHeader() -> some View {
        HStack {
            Text(NSLocalizedString("custom_sessions_title", comment: ""))
                .font(DesignTokens.Fonts.sectionTitle)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)

            Spacer()

            Text("\(sessionManager.customEntries.count)")
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .padding(.horizontal, DesignTokens.Padding.small)
                .padding(.vertical, DesignTokens.Padding.extraSmall)
                .background(
                    Capsule()
                        .fill(DesignTokens.MoonColors.textMuted.opacity(0.1))
                )
        }
    }

    @ViewBuilder
    private func customSessionsList() -> some View {
        VStack(spacing: 0) {
            if sessionManager.customEntries.isEmpty {
                emptyCustomSessionsView()
            } else {
                ForEach(Array(sessionManager.customEntries.enumerated()), id: \.element.id) { index, session in
                    customSessionRow(session, isLast: index == sessionManager.customEntries.count - 1)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .stroke(DesignTokens.BlackColors.stroke.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func customSessionRow(_ session: SessionEntry, isLast: Bool) -> some View {
        Button {
            selectedSession = session
            activeSheet = .edit(session)
        } label: { customRowLabel(session: session) }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                selectedSession = session
                activeSheet = .edit(session)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(DesignTokens.MoonColors.accentBlue)

            if !session.isDefault {
                Button(role: .destructive) {
                    selectedSession = session
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }

        if !isLast {
            Divider()
                .padding(.leading, DesignTokens.Padding.large + 20 + DesignTokens.Spacing.large)
        }
    }

    // MARK: - Row Labels (extracted to reduce function length)

    @ViewBuilder
    private func defaultRowLabel(session: SessionEntry) -> some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            Image(systemName: session.iconName)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolMedium)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                Text(session.sessionName)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                Text(
                    String.localizedStringWithFormat(
                        NSLocalizedString(
                            "descriptions_count",
                            tableName: nil,
                            bundle: .main,
                            value: "%d descriptions",
                            comment: "Pluralized descriptions count"
                        ),
                        session.descriptions.count
                    )
                )
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
            }

            Spacer()

            Image(systemName: "pencil")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolSmall)
        }
        .padding(.horizontal, DesignTokens.Padding.cardHorizontal)
        .padding(.vertical, DesignTokens.Padding.medium)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func customRowLabel(session: SessionEntry) -> some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            Image(systemName: session.iconName)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolMedium)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                Text(session.sessionName)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                if let description = session.descriptions.first, !description.isEmpty {
                    Text(description)
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

    @ViewBuilder
    private func emptyCustomSessionsView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolLarge)

            Text(NSLocalizedString("empty_custom_sessions_title", comment: ""))
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            Text(NSLocalizedString("empty_custom_sessions_subtitle", comment: ""))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DesignTokens.Padding.extraLarge)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Add Custom Session Button

    @ViewBuilder
    private func addCustomSessionButton() -> some View {
        Button {
            activeSheet = .create
        } label: {
            Label(NSLocalizedString("add_custom_session", comment: ""), systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
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

#if DEBUG
struct SessionManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SessionManagementView()
            .environmentObject(SessionManager())
            .padding()
            .background(DesignTokens.CosmosColors.background)
    }
}
#endif

import SwiftUI
import Foundation

struct SessionManagementView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSession: SessionEntry?
    @State private var showDeleteConfirm: Bool = false
    @State private var tempSessionName: String = ""
    @State private var tempDescriptions: [String] = []
    @State private var isAnyFieldFocused: Bool = false

    private enum ActiveSheet: Identifiable {
        case edit(SessionEditContext)
        case create

        var id: String {
            switch self {
            case .edit(let context):
                return "edit-\(context.entryId.uuidString)"
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
            case .edit(let context):
                ZStack {
                    DesignTokens.CosmosColors.background.ignoresSafeArea()
                    SessionEditSheetBuilder(
                        context: context,
                        tempSessionName: $tempSessionName,
                        tempDescriptions: $tempDescriptions,
                        isAnyFieldFocused: $isAnyFieldFocused,
                        onSave: {
                            handleSessionSave(context: context)
                        },
                        onCancel: {
                            dismissEditSheet()
                        }
                    )
                    .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
                }
                .presentationBackground(DesignTokens.CosmosColors.background)
            case .create:
                ZStack {
                    DesignTokens.CosmosColors.background.ignoresSafeArea()
                    NewSessionFormView()
                        .background(DesignTokens.CosmosColors.background.ignoresSafeArea())
                }
                .presentationBackground(DesignTokens.CosmosColors.background)
            }
        }
        .presentationBackground(DesignTokens.CosmosColors.background)
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

    // Helpers moved to extension below to satisfy type_body_length
}

// MARK: - SessionManagementView subviews

extension SessionManagementView {
    // Default Sessions Section
    @ViewBuilder
    fileprivate func defaultSessionsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            defaultSessionsHeader()
            defaultSessionsList()
        }
        .padding(DesignTokens.Padding.large)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .stroke(DesignTokens.BlackColors.stroke.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    fileprivate func defaultSessionsHeader() -> some View {
        Text(NSLocalizedString("default_sessions_title", comment: ""))
            .font(DesignTokens.Fonts.sectionTitle)
            .foregroundColor(DesignTokens.MoonColors.textSecondary)
    }

    @ViewBuilder
    fileprivate func defaultSessionsList() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sessionManager.defaultEntries.enumerated()), id: \.element.id) { index, session in
                defaultSessionRow(session, isLast: index == sessionManager.defaultEntries.count - 1)
            }
        }
    }

    @ViewBuilder
    fileprivate func defaultSessionRow(_ session: SessionEntry, isLast: Bool) -> some View {
        Button {
            presentEditSheet(for: session)
        } label: { self.defaultRowLabel(session: session) }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                presentEditSheet(for: session)
            } label: { Label("Edit", systemImage: "pencil") }
            .tint(DesignTokens.MoonColors.accentBlue)
        }

        if !isLast {
            Divider()
                .padding(.leading, DesignTokens.Padding.large + 20 + DesignTokens.Spacing.large)
        }
    }

    // Custom Sessions Section
    @ViewBuilder
    fileprivate func customSessionsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            customSessionsHeader()
            customSessionsList()
        }
        .padding(DesignTokens.Padding.large)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .stroke(DesignTokens.BlackColors.stroke.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    fileprivate func customSessionsHeader() -> some View {
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
    fileprivate func customSessionsList() -> some View {
        VStack(spacing: 0) {
            if sessionManager.customEntries.isEmpty {
                emptyCustomSessionsView()
            } else {
                ForEach(Array(sessionManager.customEntries.enumerated()), id: \.element.id) { index, session in
                    customSessionRow(session, isLast: index == sessionManager.customEntries.count - 1)
                }
            }
        }
    }

    @ViewBuilder
    fileprivate func customSessionRow(_ session: SessionEntry, isLast: Bool) -> some View {
        Button {
            presentEditSheet(for: session)
        } label: { self.customRowLabel(session: session) }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                presentEditSheet(for: session)
            } label: { Label("Edit", systemImage: "pencil") }
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

    @ViewBuilder
    fileprivate func emptyCustomSessionsView() -> some View {
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

    @ViewBuilder
    fileprivate func addCustomSessionButton() -> some View {
        Button {
            activeSheet = .create
        } label: {
            Label(NSLocalizedString("add_custom_session", comment: ""), systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    // Row Labels
    @ViewBuilder
    fileprivate func defaultRowLabel(session: SessionEntry) -> some View {
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
                        session.tasks.count
                    )
                )
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
    fileprivate func customRowLabel(session: SessionEntry) -> some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            Image(systemName: session.iconName)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolMedium)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraSmall) {
                Text(session.sessionName)
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)

                if let description = session.tasks.first, !description.isEmpty {
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

    // MARK: - Sheet Helpers

    private func presentEditSheet(for session: SessionEntry, descriptionIndex: Int? = nil) {
        selectedSession = session
        tempSessionName = session.sessionName
        tempDescriptions = session.tasks
        isAnyFieldFocused = false

        let context: SessionEditContext

        if session.isDefault {
            context = SessionEditContext.descriptionEdit(
                entryId: session.id,
                sessionName: session.sessionName,
                tasks: session.tasks,
                isDefault: true,
                descriptionIndex: descriptionIndex
            )
        } else {
            context = SessionEditContext.fullSessionEdit(
                entryId: session.id,
                sessionName: session.sessionName,
                tasks: session.tasks,
                isDefault: false
            )
        }

        activeSheet = .edit(context)
    }

    private func handleSessionSave(context: SessionEditContext) {
        do {
            if selectedSession?.isDefault ?? context.isDefaultSession {
                try sessionManager.updateSessionTasks(
                    sessionName: context.sessionName,
                    newTasks: tempDescriptions
                )
            } else {
                try sessionManager.addOrUpdateEntry(
                    originalKey: context.sessionName.lowercased(),
                    sessionName: tempSessionName,
                    tasks: tempDescriptions
                )
            }
            dismissEditSheet()
        } catch {
            #if DEBUG
            print("Error saving session: \(error)")
            #endif
        }
    }

    private func dismissEditSheet() {
        activeSheet = nil
        selectedSession = nil
        isAnyFieldFocused = false
        tempSessionName = ""
        tempDescriptions = []
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

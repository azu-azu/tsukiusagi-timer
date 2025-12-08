import SwiftUI
import Foundation

struct SessionManagementView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSession: SessionEntry?
    @State private var showDeleteConfirm: Bool = false
    @State private var tempSessionName: String = ""
    @State private var tempTasks: [String] = []
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
                    Text(Labels.Sections.sessionManagement)
                        .font(DesignTokens.Fonts.title)
                        .foregroundColor(DesignTokens.MoonColors.textPrimary)

                    Text(LocalizedStringKey("session_management_subtitle"))
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                }

                // Default Sessions Section (Task editing only)
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
                        tempTasks: $tempTasks,
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
                Text(LocalizedStringKey("delete_session_message \(session.sessionName)"))
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
        Text(Labels.Sections.defaultSessions)
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
            } label: { EditIconLabel() }
            .tint(DesignTokens.IconColors.pencil)
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
            Text(Labels.Sections.customSessions)
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
            } label: { EditIconLabel() }
            .tint(DesignTokens.IconColors.pencil)

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

            Text(Labels.State.noCustomSessionsYet)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            Text(LocalizedStringKey("empty_custom_sessions_subtitle"))
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
            Label(Copy.Link.addCustomSession, systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    // MARK: - Sheet Helpers

    private func presentEditSheet(for session: SessionEntry, taskIndex: Int? = nil) {
        selectedSession = session
        tempSessionName = session.sessionName
        tempTasks = session.tasks
        isAnyFieldFocused = false

        let context: SessionEditContext

        if session.isDefault {
            context = SessionEditContext.taskEdit(
                entryId: session.id,
                sessionName: session.sessionName,
                tasks: session.tasks,
                isDefault: true,
                taskIndex: taskIndex
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
                    newTasks: tempTasks
                )
            } else {
                try sessionManager.addOrUpdateEntry(
                    originalKey: context.sessionName.lowercased(),
                    sessionName: tempSessionName,
                    tasks: tempTasks
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
        tempTasks = []
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

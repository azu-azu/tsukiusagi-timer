import SwiftUI
import Foundation

struct EmbeddedSessionManagementView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSession: SessionEntry?
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
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
            // Default Sessions Section (Task editing only)
            defaultSessionsSection()

            // Custom Sessions Section (Full CRUD)
            customSessionsSection()

            // Add Custom Session Button
            addCustomSessionButton()
        }
        .padding(DesignTokens.Padding.large)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(DesignTokens.CosmosColors.cardBackground)
                .stroke(DesignTokens.BlackColors.stroke.opacity(0.1), lineWidth: 1)
        )
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
        .alert(
            Labels.Sections.deleteSession,
            isPresented: $showDeleteConfirm
        ) {
            Button(Labels.Sections.deleteSession, role: .destructive) {
                if let session = selectedSession, !session.isDefault {
                    sessionManager.deleteEntry(id: session.id)
                }
            }
            Button(Copy.Button.cancel, role: .cancel) { }
        } message: {
            if let session = selectedSession {
                Text("settings_session_delete_confirm_message \(session.sessionName)")
            }
        }
        .background(DesignTokens.CosmosColors.background)
    }

}

private extension EmbeddedSessionManagementView {
    // MARK: - Default Sessions Section

    @ViewBuilder
    func defaultSessionRow(_ session: SessionEntry, isLast: Bool) -> some View {
        Button {
            presentEditSheet(for: session)
        } label: { defaultRowLabel(session: session) }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                presentEditSheet(for: session)
        } label: {
            EditIconLabel()
        }
            .tint(DesignTokens.MoonColors.accentBlue)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("\(session.sessionName), \(session.tasks.count) tasks"))
        .accessibilityHint(Text(LocalizedStringKey("settings_accessibility_edit_tasks")))

        if !isLast {
            Divider()
                .padding(.leading, DesignTokens.Padding.large + 20 + DesignTokens.Spacing.large)
        }
    }

    // MARK: - Custom Sessions Section

    @ViewBuilder
    func customSessionRow(_ session: SessionEntry, isLast: Bool) -> some View {
        Button {
            presentEditSheet(for: session)
        } label: { customRowLabel(session: session) }
        .buttonStyle(PlainButtonStyle())
        .contextMenu { contextMenuContent(for: session) }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) { swipeActionsContent(for: session) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabel(for: session))
        .accessibilityHint(accessibilityHint())

        if !isLast {
            Divider()
                .padding(.leading, DesignTokens.Padding.large + 20 + DesignTokens.Spacing.large)
        }
    }

    @ViewBuilder
    private func contextMenuContent(for session: SessionEntry) -> some View {
        Button {
            presentEditSheet(for: session)
        } label: {
            EditIconLabel()
        }
        if !session.isDefault {
            Button(role: .destructive) {
                selectedSession = session
                showDeleteConfirm = true
            } label: {
                Label(Labels.Sections.deleteSession, systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func swipeActionsContent(for session: SessionEntry) -> some View {
        Button {
            presentEditSheet(for: session)
        } label: {
            EditIconLabel()
        }
        .tint(DesignTokens.MoonColors.accentBlue)
        if !session.isDefault {
            Button(role: .destructive) {
                selectedSession = session
                showDeleteConfirm = true
            } label: {
                Label(Labels.Sections.deleteSession, systemImage: "trash")
            }
        }
    }

    private func accessibilityLabel(for session: SessionEntry) -> Text {
        Text(session.tasks.first.flatMap { task in
            LocalizedStringKey("\(session.sessionName): \(task)")
        } ?? LocalizedStringKey(session.sessionName))
    }

    private func accessibilityHint() -> Text {
        Text(LocalizedStringKey("settings_accessibility_edit_actions"))
    }

    // MARK: - Row Labels (extracted)

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

                Text(
                    String.localizedStringWithFormat(
                        NSLocalizedString(
                            "tasks_count",
                            tableName: nil,
                            bundle: .main,
                            value: "%d tasks",
                            comment: "Pluralized tasks count"
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

    @ViewBuilder
    func defaultSessionsSection() -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sessionManager.defaultEntries.enumerated()), id: \.element.id) { index, session in
                defaultSessionRow(session, isLast: index == sessionManager.defaultEntries.count - 1)
            }
        }
    }

    @ViewBuilder
    func customSessionsSection() -> some View {
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

    // MARK: - Sheet Helpers

    func presentEditSheet(for session: SessionEntry, taskIndex: Int? = nil) {
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

    func handleSessionSave(context: SessionEditContext) {
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

    func dismissEditSheet() {
        activeSheet = nil
        selectedSession = nil
        isAnyFieldFocused = false
        tempSessionName = ""
        tempTasks = []
    }

    @ViewBuilder
    func emptyCustomSessionsView() -> some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolLarge)

            Text(Labels.State.noCustomSessionsYet)
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            Text(LocalizedStringKey("empty_custom_sessions_subtitle"))
                .font(.caption2)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DesignTokens.Padding.large)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Add Custom Session Button

    @ViewBuilder
    func addCustomSessionButton() -> some View {
        Button {
            activeSheet = .create
        } label: {
            Label(Copy.Link.addCustomSession, systemImage: "plus")
                .font(DesignTokens.Fonts.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Padding.small)
        }
        .buttonStyle(.borderedProminent)
    }
}

#if DEBUG
struct EmbeddedSessionManagementView_Previews: PreviewProvider {
    static var previews: some View {
        EmbeddedSessionManagementView()
            .environmentObject(SessionManager())
            .padding()
            .background(DesignTokens.CosmosColors.background)
    }
}
#endif

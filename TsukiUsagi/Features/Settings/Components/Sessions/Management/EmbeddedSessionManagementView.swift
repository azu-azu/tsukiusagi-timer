import SwiftUI
import Foundation

struct EmbeddedSessionManagementView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSession: SessionEntry?
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
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.extraLarge) {
            // Default Sessions Section (Description editing only)
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
            } label: { Label("Edit", systemImage: "pencil") }
            .tint(DesignTokens.MoonColors.accentBlue)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("\(session.sessionName), \(session.descriptions.count) descriptions"))
        .accessibilityHint(Text("Tap to edit descriptions"))

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
        .contextMenu {
            Button {
                presentEditSheet(for: session)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            if !session.isDefault {
                Button(role: .destructive) {
                    selectedSession = session
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
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
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("\(session.sessionName)" + (session.descriptions.first.flatMap { ": \($0)" } ?? "")))
        .accessibilityHint(Text("Tap to edit. Long-press for more actions."))

        if !isLast {
            Divider()
                .padding(.leading, DesignTokens.Padding.large + 20 + DesignTokens.Spacing.large)
        }
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

    func presentEditSheet(for session: SessionEntry, descriptionIndex: Int? = nil) {
        selectedSession = session
        tempSessionName = session.sessionName
        tempDescriptions = session.descriptions
        isAnyFieldFocused = false

        let context: SessionEditContext

        if session.isDefault {
            context = SessionEditContext.descriptionEdit(
                entryId: session.id,
                sessionName: session.sessionName,
                descriptions: session.descriptions,
                isDefault: true,
                descriptionIndex: descriptionIndex
            )
        } else {
            context = SessionEditContext.fullSessionEdit(
                entryId: session.id,
                sessionName: session.sessionName,
                descriptions: session.descriptions,
                isDefault: false
            )
        }

        activeSheet = .edit(context)
    }

    func handleSessionSave(context: SessionEditContext) {
        do {
            if selectedSession?.isDefault ?? context.isDefaultSession {
                try sessionManager.updateSessionDescriptions(
                    sessionName: context.sessionName,
                    newDescriptions: tempDescriptions
                )
            } else {
                try sessionManager.addOrUpdateEntry(
                    originalKey: context.sessionName.lowercased(),
                    sessionName: tempSessionName,
                    descriptions: tempDescriptions
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
        tempDescriptions = []
    }

    @ViewBuilder
    func emptyCustomSessionsView() -> some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: "folder.badge.plus")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(DesignTokens.Fonts.symbolLarge)

            Text(NSLocalizedString("empty_custom_sessions_title", comment: ""))
                .font(DesignTokens.Fonts.caption)
                .foregroundColor(DesignTokens.MoonColors.textMuted)

            Text(NSLocalizedString("empty_custom_sessions_subtitle", comment: ""))
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
            Label(NSLocalizedString("add_custom_session", comment: ""), systemImage: "plus")
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

import SwiftUI

struct NewSessionFormView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedSessionForEdit: String = ""
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var errorTitle: String = "Error"
    @State private var showEditView = false
    @State private var showCreateView = false
    
    private var isEditButtonEnabled: Bool {
        !selectedSessionForEdit.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Dropdown Selector Section
            dropdownSelectorSection()
            
            // Action Buttons Section
            actionButtonsSection()
            
            // Single Unified Session List Display
            unifiedSessionListSection()
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(errorTitle),
                message: Text(errorMessage ?? ""),
                dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showEditView) {
            EditSessionStubView(sessionName: selectedSessionForEdit)
        }
        .sheet(isPresented: $showCreateView) {
            CreateSessionStubView()
        }
    }
    
    // MARK: - Dropdown Selector Section
    
    @ViewBuilder
    private func dropdownSelectorSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose existing session to edit")
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textSecondary)
            
            Menu {
                // All sessions for editing (grouped)
                Section("DEFAULT") {
                    ForEach(sessionManager.defaultEntries) { entry in
                        Button {
                            selectedSessionForEdit = entry.sessionName
                        } label: {
                            HStack {
                                Text(entry.sessionName)
                                if selectedSessionForEdit == entry.sessionName {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                if !sessionManager.customEntries.isEmpty {
                    Section("CUSTOM") {
                        ForEach(sessionManager.customEntries) { entry in
                            Button {
                                selectedSessionForEdit = entry.sessionName
                            } label: {
                                HStack {
                                    Text(entry.sessionName)
                                    if selectedSessionForEdit == entry.sessionName {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedSessionForEdit.isEmpty ? "Select a session..." : selectedSessionForEdit)
                        .foregroundColor(selectedSessionForEdit.isEmpty ? 
                                       DesignTokens.MoonColors.textMuted : 
                                       DesignTokens.MoonColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignTokens.CosmosColors.cardBackground)
                        .stroke(DesignTokens.BlackColors.stroke, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    @ViewBuilder
    private func actionButtonsSection() -> some View {
        HStack(spacing: 12) {
            Button("Edit Selected") {
                showEditView = true
            }
            .buttonStyle(.bordered)
            .disabled(!isEditButtonEnabled)
            
            Button("Create New") {
                showCreateView = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Unified Session List Display
    
    @ViewBuilder
    private func unifiedSessionListSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // DEFAULT Sessions
            VStack(alignment: .leading, spacing: 8) {
                Text("DEFAULT")
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(sessionManager.defaultEntries) { entry in
                        sessionListItem(entry.sessionName, isDefault: true)
                    }
                }
            }
            
            // Light section separator
            Divider()
                .background(DesignTokens.BlackColors.stroke.opacity(0.3))
            
            // CUSTOM Sessions
            VStack(alignment: .leading, spacing: 8) {
                Text("CUSTOM")
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                
                if sessionManager.customEntries.isEmpty {
                    Text("No custom sessions. Tap Create New to add.")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .italic()
                        .padding(.leading, 8)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(sessionManager.customEntries) { entry in
                            sessionListItem(entry.sessionName, isDefault: false)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Session List Item
    
    @ViewBuilder
    private func sessionListItem(_ sessionName: String, isDefault: Bool) -> some View {
        HStack(spacing: 8) {
            Text("•")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(.caption)
            
            Text(sessionName)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            
            Spacer()
            
            if !isDefault {
                Text("editable")
                    .font(DesignTokens.Fonts.caption)
                    .foregroundColor(DesignTokens.MoonColors.textMuted)
                    .italic()
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Stub Views

struct EditSessionStubView: View {
    let sessionName: String
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""
    @State private var editedDescription: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Editing: \(sessionName)")
                    .font(DesignTokens.Fonts.title)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Name")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    
                    TextField("Enter session name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    
                    TextField("Enter description (optional)", text: $editedDescription)
                        .textFieldStyle(.roundedBorder)
                }
                
                Spacer()
                
                Button("Save Changes") {
                    // TODO: Implement save functionality
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            editedName = sessionName
        }
    }
}

struct CreateSessionStubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newSessionName: String = ""
    @State private var newDescription: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Create New Session")
                    .font(DesignTokens.Fonts.title)
                    .foregroundColor(DesignTokens.MoonColors.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Name")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    
                    TextField("Enter session name", text: $newSessionName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(DesignTokens.Fonts.label)
                        .foregroundColor(DesignTokens.MoonColors.textSecondary)
                    
                    TextField("Enter description (optional)", text: $newDescription)
                        .textFieldStyle(.roundedBorder)
                }
                
                Spacer()
                
                Button("Create Session") {
                    // TODO: Implement create functionality
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newSessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct NewSessionFormView_Previews: PreviewProvider {
    static var previews: some View {
        NewSessionFormView()
            .environmentObject(SessionManager())
            .padding()
            .background(DesignTokens.CosmosColors.background)
    }
}
#endif
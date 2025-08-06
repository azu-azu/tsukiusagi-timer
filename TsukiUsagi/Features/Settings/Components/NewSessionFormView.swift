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
        VStack(alignment: .leading, spacing: 20) {
            // Session Selection Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose existing session to edit")
                    .font(DesignTokens.Fonts.label)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                
                sessionDropdownMenu()
                
                // Action Buttons
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
            
            // Session List
            VStack(alignment: .leading, spacing: 12) {
                Text("All Sessions")
                    .font(DesignTokens.Fonts.sectionTitle)
                    .foregroundColor(DesignTokens.MoonColors.textSecondary)
                
                sessionList()
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
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
    
    // MARK: - Session Dropdown Menu
    
    @ViewBuilder
    private func sessionDropdownMenu() -> some View {
        Menu {
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
            
            if !sessionManager.customEntries.isEmpty {
                Divider()
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
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignTokens.CosmosColors.cardBackground)
                    .stroke(DesignTokens.BlackColors.stroke.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Session List
    
    @ViewBuilder
    private func sessionList() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // All sessions in one clean list
            ForEach(sessionManager.defaultEntries) { entry in
                sessionListItem(entry.sessionName)
            }
            
            if !sessionManager.customEntries.isEmpty {
                // Subtle divider
                Rectangle()
                    .fill(DesignTokens.BlackColors.stroke.opacity(0.2))
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                ForEach(sessionManager.customEntries) { entry in
                    sessionListItem(entry.sessionName)
                }
            } else {
                // Empty state with subtle styling
                Rectangle()
                    .fill(DesignTokens.BlackColors.stroke.opacity(0.2))
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                HStack(spacing: 10) {
                    Text("•")
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .font(.system(size: 12, weight: .medium))
                    
                    Text("No custom sessions yet. Tap Create New to add.")
                        .font(DesignTokens.Fonts.caption)
                        .foregroundColor(DesignTokens.MoonColors.textMuted)
                        .italic()
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.CosmosColors.cardBackground)
        )
    }
    
    // MARK: - Session List Item
    
    @ViewBuilder
    private func sessionListItem(_ sessionName: String) -> some View {
        HStack(spacing: 10) {
            Text("•")
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .font(.system(size: 12, weight: .medium))
            
            Text(sessionName)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
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
            VStack(alignment: .leading, spacing: 24) {
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
                .frame(maxWidth: .infinity)
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
            VStack(alignment: .leading, spacing: 24) {
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
                .frame(maxWidth: .infinity)
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
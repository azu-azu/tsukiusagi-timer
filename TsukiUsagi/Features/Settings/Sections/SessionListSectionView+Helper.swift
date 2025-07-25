import SwiftUI

// MARK: - SessionListSectionView Helper Functions

extension SessionListSectionView {

    // MARK: - Save Methods

    func saveDescriptionEdit(context: SessionEditContext) {
        do {
            try sessionManager.updateSessionDescriptions(
                sessionName: context.sessionName,
                newDescriptions: tempDescriptions
            )
        } catch {
            errorMessage = IdentifiableError(message: error.localizedDescription)
        }
    }

    func saveFullSessionEdit(context: SessionEditContext) {
        guard case .fullSession = context.editMode else { return }

        do {
            try sessionManager.addOrUpdateEntry(
                originalKey: context.sessionName.lowercased(),
                sessionName: tempSessionName,
                descriptions: tempDescriptions
            )
        } catch {
            errorMessage = IdentifiableError(message: error.localizedDescription)
        }
    }
}

import SwiftUI

struct LargeTextEditorSheet: View {
    @Binding var text: String
    let title: String
    let placeholder: LocalizedStringKey
    let onClose: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.CosmosColors.background.ignoresSafeArea()

                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: 300)
                    .padding(16)
                    .background(DesignTokens.WhiteColors.surface)
                    .cornerRadius(10)
                    .scrollContentBackground(.hidden)
                    .overlay(placeholderOverlay)
                    .accessibilityIdentifier("large_text_editor_sheet_editor")
                    .padding()
            }
            .navigationTitle(Text(title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CollapseIconButton(accessibilityIdentifier: "large_text_editor_sheet_close") {
                        onClose()
                    }
                }
            }
            .presentationDetents([.large])
            .keyboardCloseToolbar(labelStyle: .iconWithText(Copy.Button.close)) {
                isFocused = false
                Keyboard.dismiss()
            }
            .onAppear {
                DispatchQueue.main.async { isFocused = true }
            }
        }
    }

    @ViewBuilder
    private var placeholderOverlay: some View {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(placeholder)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.MoonColors.textMuted)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
        }
    }
}

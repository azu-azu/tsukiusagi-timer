import SwiftUI

struct DirectDescriptionEditTest: View {
    @State private var testDescriptions: [String] = ["First item", "Second item"]
    @State private var isAnyFieldFocused: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Direct Test - Count: \(testDescriptions.count)")
                    .font(DesignTokens.Fonts.labelBold)
                    .padding()

                DescriptionEditContent(
                    sessionName: "Test Session",
                    descriptions: testDescriptions,
                    editingIndex: nil,
                    onDescriptionsChange: { newDescriptions in
                        print("🟦🟦🟦 Direct test received change: \(newDescriptions)")
                        testDescriptions = newDescriptions
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    }
                )

                Spacer()

                // 状態確認用
                Text("Current descriptions: \(testDescriptions.joined(separator: ", "))")
                    .font(DesignTokens.Fonts.caption)
                    .padding()
            }
            .navigationTitle("Direct Test")
        }
    }
}

#if DEBUG
struct DirectDescriptionEditTest_Previews: PreviewProvider {
    static var previews: some View {
        DirectDescriptionEditTest()
    }
}
#endif

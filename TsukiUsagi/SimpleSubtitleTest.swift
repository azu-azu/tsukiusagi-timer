import SwiftUI

struct DirectSubtitleEditTest: View {
    @State private var testSubtitles: [String] = ["First item", "Second item"]
    @State private var isAnyFieldFocused: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Direct Test - Count: \(testSubtitles.count)")
                    .font(.headline)
                    .padding()

                SubtitleEditContent(
                    sessionName: "Test Session",
                    subtitles: testSubtitles,
                    editingIndex: nil,
                    onSubtitlesChange: { newSubtitles in
                        print("🟦🟦🟦 Direct test received change: \(newSubtitles)")
                        testSubtitles = newSubtitles
                    },
                    isAnyFieldFocused: $isAnyFieldFocused,
                    onClearFocus: {
                        isAnyFieldFocused = false
                    }
                )

                Spacer()

                // 状態確認用
                Text("Current subtitles: \(testSubtitles.joined(separator: ", "))")
                    .font(.caption)
                    .padding()
            }
            .navigationTitle("Direct Test")
        }
    }
}

#if DEBUG
struct DirectSubtitleEditTest_Previews: PreviewProvider {
    static var previews: some View {
        DirectSubtitleEditTest()
    }
}
#endif

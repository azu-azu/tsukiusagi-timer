import SwiftUI

struct RecordedTimesView: View {
    let formattedStartTime: String
    let formattedEndTime: String
    let actualSessionMinutes: Int
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                // 上２行：中央
                VStack(spacing: 4) {
                    Text("Start 🌕 \(formattedStartTime)")
                    Text("Final 🌑 \(formattedEndTime)")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.Colors.textWhite)
            }

            // ３行目の分数表示
            Text("-- \(actualSessionMinutes) min")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .font(DesignTokens.Fonts.label)
                .foregroundColor(DesignTokens.Colors.textWhite)
                .frame(maxWidth: 110)

            // ✏️
            HStack {
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(DesignTokens.Fonts.title)
                        .foregroundColor(.yellow)
                }
                .accessibilityLabel("Edit session record")
                .accessibilityHint("Tap to edit start time, end time, and session details")
            }
            .frame(maxWidth: 110)
        }
        .padding(.top, 20)
        .background(Color.clear)
        .accessibilityElement(children: .combine)
    }
}

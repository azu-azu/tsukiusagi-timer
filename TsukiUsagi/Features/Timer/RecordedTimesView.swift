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
                .titleWhiteAvenir(size: 18, weight: .regular)
            }

            // ３行目の分数表示
            Text("-- \(actualSessionMinutes) min")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .titleWhiteAvenir(size: 18, weight: .regular)
                .frame(maxWidth: 110)

            // ✏️
            HStack {
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 30))
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
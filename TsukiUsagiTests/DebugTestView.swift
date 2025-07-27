import SwiftUI

struct FontDebugTestView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Nunito Bold Test")
                .font(.custom("Nunito-Bold", size: 24))
                .foregroundColor(.blue)

            Text("System Font Test")
                .font(.system(size: 24))
                .foregroundColor(.gray)
        }
        .onAppear {
            print("🟢 FontDebugTestView appeared")

            print("🔍 フォント一覧:")
            for family in UIFont.familyNames.sorted() {
                print("📂 \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("    🔤 \(name)")
                }
            }
        }
    }
}

#Preview {
    FontDebugTestView()
}


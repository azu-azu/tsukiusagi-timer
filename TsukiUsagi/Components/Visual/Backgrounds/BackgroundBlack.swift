import SwiftUI

struct BackgroundBlack: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#0a0a0a"), location: 0.0), // ほぼ黒
                .init(color: Color(hex: "#121212"), location: 0.7), // 深い黒
                .init(color: Color(hex: "#1a1a1a"), location: 1.0) // やや明るい黒
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    BackgroundBlack()
}

// このグラデーションは真っ黒一色よりも以下の理由で優れていると考えられます：
// 1. **視覚的な深み**:
//     - 単一の黒色よりも、微妙なグラデーションがあることで画面に奥行きと深みが生まれます。これにより、UIの要素がより立体的に見えます。
// 2. **目の疲れの軽減**:
//     - 完全な黒（`#000000`）は、特に暗い環境で見ると目が疲れやすくなります。現在の設定では、最も暗い部分でも `#0a0a0a` という微妙な明るさがあり、目への負担を軽減できます。
// 3. **モダンな印象**:
//     - 多くの現代的なアプリやウェブサイトでは、完全な黒ではなく、微妙なグラデーションを持つ黒を使用しています。これにより、より洗練された印象を与えることができます。
// 4. **コントラストの調整**:
//     - グラデーションを使用することで、画面上部と下部で微妙に異なるコントラストを提供でき、UI要素の視認性を調整しやすくなります。

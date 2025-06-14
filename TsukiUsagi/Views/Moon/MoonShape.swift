import SwiftUI

struct MoonShape: View {
    let fillColor: Color
    let radius: CGFloat

    init(fillColor: Color, radius: CGFloat = 200) {
        self.fillColor = fillColor
        self.radius = radius
    }

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: radius, height: radius)
    }
}

#Preview {
    MoonShape(fillColor: .yellow)
}
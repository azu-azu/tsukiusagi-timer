//
//  UsagiView_1.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import SwiftUI

struct UsagiViewOne: View {
    // 呼び出し側でサイズを渡せるようにプロパティ化
    let width: CGFloat
    let height: CGFloat

    @State private var float = false
    @Environment(\.displayScale) private var scale // ← 1x / 2x / 3x

    var body: some View {
        let amplitude: CGFloat = 6 / scale // ← 実ピクセルで常に約6px

        Image("usagi_1") // 元の画像に戻す
            .resizable()
            .frame(width: width, height: height)
            .offset(y: float ? -amplitude : amplitude)
            // .onAppear {
            //     withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            //         float = true
            //     }
            // }
    }
}

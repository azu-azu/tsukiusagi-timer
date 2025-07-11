//
//  UsagiView_2.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import SwiftUI

struct UsagiViewTwo: View {
    @State private var float = false

    var body: some View {
        Image("usagi_2")
            .resizable()
            .frame(width: 80, height: 80)
            .offset(y: float ? -10 : 10)
            .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: float)
            .onAppear {
                float = true
            }
    }
}

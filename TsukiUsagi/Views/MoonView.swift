//
//  MoonView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import SwiftUI

struct MoonView: View {
	var body: some View {
		Circle()
			.fill(Color(red: 1.0, green: 0.95, blue: 0.82))
			.frame(width: 200, height: 200)
			.blur(radius: 10)
			.offset(y: -150)
	}
}


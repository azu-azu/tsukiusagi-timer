//
//  MoonView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import SwiftUI

struct MoonView: View {
	@State private var animate = false
	@State private var float = false

	var moonSize: CGFloat = 200
	var paddingY: CGFloat
	var glitterText: String

	// 紫の影（アニメーション）
	var nearY: CGFloat { moonSize } // 上の位置
	var farY:  CGFloat = 44  // 下の位置
	var duration: Double = 17

	// 🐇
	var usagiWidth:  CGFloat { moonSize * 0.575 }
	var usagiHeight: CGFloat { moonSize * 0.75  }
	var usagiOffsetX: CGFloat { (-moonSize / 2) + (usagiWidth / 2) }   // フチ合わせ式

	var body: some View {
		ZStack {
			// 🌕 にじみ光（後ろのぼかし）
			MoonShape(fillColor: Color(hex: "#ffff55").opacity(0.3), radius: moonSize)
				.compositingGroup()
				.blur(radius: 50)

			// 🌕 月の本体（黄色）
			MoonShape(fillColor: Color(hex: "#ffff55"), radius: moonSize)
				.blur(radius: 4)

			// 🐇
			ZStack {
				UsagiView_1(width: usagiWidth, height: usagiHeight)
					.blur(radius: 2)
					.opacity(0.3)
					.offset(x: usagiOffsetX)
			}

			// 🌘 紫の影（アニメーション）
			ZStack {
				MoonShadow(moonSize:moonSize, duration: duration, nearY: nearY, farY: farY)

				// 🌑 クレーター（うっすらした内側の模様）
				CraterCluster()
				CraterCluster(scale: 0.7)         // 70% に縮小
					.offset(x:  30, y: -25)
			}
			.rotationEffect(.degrees(227)) // CSSのrotate(227deg) に相当
			.mask(
				MoonShape(fillColor: .white, radius: moonSize)
					.scaleEffect(1.05)
			)

			// ✨ キラキラ文字
			Text(glitterText)
				.glitter()
				.offset(y:20)
		}
		.padding(.top, paddingY)
		.onAppear {
			animate = true
		}
	}
}

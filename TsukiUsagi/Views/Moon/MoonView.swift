//
//  View.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import SwiftUI

struct MoonView: View {
	@State private var animate = false
	@State private var float = false

	private let nearY: CGFloat = 200 // 上の位置
	private let farY:  CGFloat = 44  // 下の位置
	private let duration: Double = 17
	let offsetY: CGFloat
	let glitterText: String

	var body: some View {
		ZStack {
			// 🌕 にじみ光（後ろのぼかし）
			MoonShape(fillColor: Color(hex: "#ffff55").opacity(0.7), radius: 200)
				.compositingGroup()
				.blur(radius: 100)

			// 🌕 月の本体（黄色）
			MoonShape(fillColor: Color(hex: "#ffff55"), radius: 200)
				.blur(radius: 4)

			// 🐇
			ZStack {
				UsagiView_1(width: 115, height: 150)
					.blur(radius: 1)              // ぼかし量
					.opacity(0.5)                // 透け度を
					.offset(x: -40)
			}

			// 🌘 紫の影（アニメーション）
			ZStack {
				MoonShadow(duration: duration, nearY: nearY, farY: farY)

				// 🌑 クレーター（うっすらした内側の模様）
				CraterCluster()
				CraterCluster(scale: 0.7)         // 70% に縮小
					.offset(x:  30, y: -25)
			}
			.rotationEffect(.degrees(227)) // CSSのrotate(227deg) に相当
			.mask(
				MoonShape(fillColor: .white, radius: 200)
					.scaleEffect(1.05)
			)

			// ✨ キラキラ文字
			GlitterText(text: glitterText)
				.offset(x: 20)
		}
		.offset(y: offsetY)
		.onAppear {
			animate = true
		}
	}
}

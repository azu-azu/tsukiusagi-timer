//
//  MoonView.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import SwiftUI

struct PoeticMoonView: View {
	@State private var animate = false

	var body: some View {
		ZStack {
			// 🌕 にじみ光（後ろのぼかし）
			Circle()
				.fill(Color(hex: "#ffff55").opacity(0.7))
				.frame(width: 200, height: 200)
				.compositingGroup()
				.blur(radius: 100)

			// 🌕 月の本体（黄色）
			Circle()
				.fill(Color(hex: "#ffff55"))
				.frame(width: 200, height: 200)
				.blur(radius: 4)

			// 🌘 紫の影（アニメーション）
			ZStack {
				// アニメーションする影
				Circle()
					.fill(Color(hex: "#660066").opacity(0.9))
					.frame(width: 200, height: 200)
					.offset(y: animate ? 44 : 272)
					.blur(radius: 4)
					.animation(
						.easeInOut(duration: 17)
							.repeatForever(autoreverses: true),
						value: animate
					)

				// 🌑 クレーター（うっすらした内側の模様）
				Group {
					Circle()
						.fill(Color.white.opacity(0.05))
						.frame(width: 20, height: 20)
						.offset(x: -30, y: 10)

					Circle()
						.fill(Color.white.opacity(0.05))
						.frame(width: 14, height: 14)
						.offset(x: 20, y: -25)

					Circle()
						.fill(Color.white.opacity(0.04))
						.frame(width: 10, height: 10)
						.offset(x: 10, y: 25)
				}
			}
			.rotationEffect(.degrees(227)) // CSSのrotate(227deg) に相当
			.mask(
				Circle()
					.scaleEffect(1.05)
			)
		}
		.offset(y: -150)
		.onAppear {
			animate = true
		}
	}
}




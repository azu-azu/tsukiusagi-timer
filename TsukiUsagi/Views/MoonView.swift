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

	private let nearY: CGFloat = 200     // 上の位置
	private let farY:  CGFloat = 44    // 下の位置
	private let duration: Double = 10
	
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

			// 🐇
			ZStack {
				UsagiView_1(width: 115, height: 150)
					.blur(radius: 1)              // ぼかし量
					.opacity(0.5)                // 透け度を
					.offset(x: -40)
			}


			// 🌘 紫の影（アニメーション）
			ZStack {
				// アニメーションする影
				Circle()
					.fill(Color(hex: "#660066").opacity(0.9))
					.frame(width: 200, height: 200)
					.offset(y: animate ? nearY : farY)
					.blur(radius: 4)
					.onAppear {
						withAnimation(
							Animation
								.timingCurve(0.4, 0, 0.8, 1.0, duration: duration)
								.repeatForever(autoreverses: true)
						) {
							animate.toggle()  // → 動き出す
						}
					}

				// 🌑 クレーター（うっすらした内側の模様）
				CraterCluster()
				CraterCluster(scale: 0.7)         // 70% に縮小
					.offset(x:  30, y: -25)

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




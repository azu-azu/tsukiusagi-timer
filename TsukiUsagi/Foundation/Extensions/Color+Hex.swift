//
//  Color+Hex.swift
//  TsukiUsagi
//
//  Created by azu-azu on 2025/06/12.
//

import SwiftUI

extension Color {
	init(hex: String) {
		let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
		let scanner = Scanner(string: hex)
		if hex.hasPrefix("#") {
			scanner.currentIndex = hex.index(after: hex.startIndex)
		}

		var rgb: UInt64 = 0
		scanner.scanHexInt64(&rgb)

		let r = Double((rgb >> 16) & 0xFF) / 255.0
		let g = Double((rgb >> 8) & 0xFF) / 255.0
		let b = Double(rgb & 0xFF) / 255.0

		self.init(red: r, green: g, blue: b)
	}

    /// 夜空の背景（ZStack全体に使用）
    // static let moonBackground = Color(red: 18/255, green: 28/255, blue: 44/255)
	static let moonBackground = Color(hex: "#060c22")

    /// 月明かりのカード背景（セクションやボタン）
    // static let moonCardBackground = Color(red: 45/255, green: 54/255, blue: 77/255)
    // static let moonCardBackground = Color(red: 255/255, green: 255/255, blue: 255/255)
    static let moonCardBackground = Color(hex: "#4b95ba")

    /// やさしい白文字（テキスト全般）
    static let moonTextPrimary = Color.white.opacity(0.9)
    static let moonTextSecondary = Color.white.opacity(0.6)
    static let moonTextMuted = Color.white.opacity(0.35)

    /// 月の光を思わせる青（アクセント、リンクカラー）
    static let moonAccentBlue = Color(red: 97/255, green: 163/255, blue: 242/255)

    /// エラー表示用の赤色（バリデーションエラーなど）
    static let moonErrorBackground = Color.red.opacity(0.8)
}



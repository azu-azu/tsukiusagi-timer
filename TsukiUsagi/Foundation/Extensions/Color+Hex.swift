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

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    /// 夜空の背景（ZStack全体に使用）
    static let cosmosBackground = Color(hex: "#060c22").opacity(0.95)

    /// 月明かりのカード背景（セクションやボタン）
    static let moonCardBackground = Color(hex: "#ffffff").opacity(0.15)

    /// 月の光を思わせる青（アクセント、リンクカラー）
    static let moonAccentBlue = Color(red: 97 / 255, green: 163 / 255, blue: 242 / 255)

    /// エラー表示用の赤色（バリデーションエラーなど）
    static let moonErrorBackground = Color.red.opacity(0.8)
}

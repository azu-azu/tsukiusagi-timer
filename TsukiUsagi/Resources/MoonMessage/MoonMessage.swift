//  MoonMessage.swift
//  TsukiUsagi
//
//  “文字列リソース” を一元管理
import Foundation

enum MoonMessage {
    static let finalTitle   = "Quiet Moon"
    static let messages: [String] = [
        "Centered means feeling emotionally stable, grounded, and calmly, regardless of what's happening outside.",
        "Silence doesn’t mean emptiness. It means space to breathe.",
        "The moon doesn’t rush. Yet it completes its cycle, every time.",
        "Your stillness is not a pause. It is power in rest.",
        "Focus is not tension. It’s the art of being undisturbed."
    ]

    static func random() -> String {
        messages.randomElement() ?? ""
    }
}


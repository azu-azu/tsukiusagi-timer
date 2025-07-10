// MoonMessage.swift

import Foundation

struct MoonMessageEntry {
    let lines: [String]
}

enum MoonMessage {
    static let messages: [MoonMessageEntry] = [
        MoonMessageEntry(lines: [
            "There is no sound in space.",
            "Stars explode in silence.",
            "",
            "At its core, every work is quiet.",
        ]),

        MoonMessageEntry(lines: [
            "The Moon always shows the same face to Earth.",
            "",
            "There’s a side of the Moon we’ll never see—",
            "",
            "There’s a side of you no one will ever see.",
        ]),

        MoonMessageEntry(lines: [
            "'Joy is not in things.",
            "it is in us.'",
            "– Richard Wagner",
            "",
            "",
            "It might come like moonlight—",
            "soft, slow, ",
            "and never asking.",
        ]),

        MoonMessageEntry(lines: [
            "True joy drifts in,",
            "like the moon—",
            "",
            "never loud, never rushed.",

            // 喜びは、月明かりのよう。
            // ふわっと静かにやってくる。
            // “drift in” ＝「漂うように入ってくる」
        ]),

        MoonMessageEntry(lines: [
            "What if",
            "the Moon simply saw—",
            "",
            "not what you’ve done,",
            "but how softly you’ve been?",

            // 月は静かに見ている——
            // 何をしたか、ではなく、
            // どれだけ優しくあれたかを。
        ]),

        MoonMessageEntry(lines: [
            "The Moon has no atmosphere, so sound cannot exist there.",
            "",
            "Even if you scream, no sound would ever form.",
            "",
            "It’s okay for silence to be the answer.",

            // 月には、音が存在しない。
            // それでも、静かに輝いていられる。
        ]),

        MoonMessageEntry(lines: [
            "The Moon always watches us.",
            "",
            "She sees your work.",
            "You are quietly seen.",
        ]),

        MoonMessageEntry(lines: [
            "The Moon is always there, in the same place.",
            "",
            "You are quietly seen.",
            "",
            "You don’t need to shout to be noticed.",
        ]),

        MoonMessageEntry(lines: [
            "The Moon’s gravity pulls on Earth's oceans, creating tides.",
            "",
            "Even in silence, the Moon moves the sea.",
            "",
            "You don’t need noise to change the world.",
        ]),

        MoonMessageEntry(lines: [
            "Because there is no wind or water, ",
            "",
            "astronaut footprints on the Moon may last for millions of years.",
            "",
            "You’re erased only when something erases you.",
        ]),

        MoonMessageEntry(lines: [
            "On the Moon, a day is 29.5 Earth days.",
            "",
            "For a human, that's about the speed of a brisk walk.",
            "",
            "The Moon moves slowly.",
            "Yet its influence is vast.",
        ]),

        MoonMessageEntry(lines: [
            "On the Moon, shadows are sharp.",
            "",
            "No air, no blur—",
            "just clarity from what's absent.",
        ]),

        MoonMessageEntry(lines: [
            "The Moon moves the tides without a sound.",
            "But the Moon doesn't intend to pull the sea.",
            "",
            "We move each other—silently.",
        ]),

        MoonMessageEntry(lines: [
            "The Moon quietly pulls the sea and stirs the waves.",
            "",
            "You, too, pull someone—",

            // 僕らは皆、ただここにいるだけで
            // 誰かの心の波を、静かに動かしているんだ
        ]),

        MoonMessageEntry(lines: [
            "You often feel tired, ",
            "not because you've done too much,",
            "",
            "but because you've done too little of what sparks a light in you.",
            "",
            "— Alexander Den Heijer",
        ]),

        MoonMessageEntry(lines: [
            "The Moon doesn’t shine.",
            "It just stays close to the Sun.",
            "Sometimes, being near is enough to glow.",

            // 光らなくてもいい
            // 太陽のそばにいるだけで、輝ける
        ]),

        MoonMessageEntry(lines: [
            "You often feel tired, ",
            "You often feel tired, ",
            "You often feel tired, ",
            "You often feel tired, ",
            "You often feel tired, ",
            "You often feel tired, ",
            "You often feel tired, ",
            "You often feel tired, ",
            "You often feel tired, ",
            "not because you've done too much,",
            "",
            "but because you've done too little of what sparks a light in you.",
            "",
            "— Alexander Den Heijer",
        ]),
    ]

    static func random() -> MoonMessageEntry {
        messages.randomElement() ?? MoonMessageEntry(lines: [""])
    }
}

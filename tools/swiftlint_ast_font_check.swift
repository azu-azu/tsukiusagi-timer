import SwiftSyntax
import SwiftSyntaxParser

// AST Lint PoC: .font(.system...)や.font(.custom...)の検知
// 使い方: swift run tools/swiftlint_ast_font_check.swift <target_dir>

import Foundation

func checkFonts(in file: String) {
    guard let source = try? String(contentsOfFile: file) else { return }
    guard let tree = try? SyntaxParser.parse(source: source) else { return }
    var visitor = FontCallVisitor(file: file)
    visitor.walk(tree)
}

class FontCallVisitor: SyntaxVisitor {
    let file: String
    init(file: String) { self.file = file }
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let called = node.calledExpression.as(MemberAccessExprSyntax.self),
           called.name.text == "font" {
            if let arg = node.argumentList.first?.expression.as(FunctionCallExprSyntax.self),
               let fontType = arg.calledExpression.as(MemberAccessExprSyntax.self)?.name.text,
               ["system", "custom"].contains(fontType) {
                let pos = node.positionAfterSkippingLeadingTrivia
                print("\(file):\(pos.line ?? 0):\(pos.column ?? 0): error: Forbidden direct font usage detected in AST.")
                print("→ 修正例: DesignTokens.Fonts.labelBold")
                print("→ See: /docs/lint_exceptions.md")
                print("→ Learn More: /docs/font_guidelines.md#why-forbidden\n")
            }
        }
        return .visitChildren
    }
}

// --- 実行部 ---
if CommandLine.arguments.count < 2 {
    print("Usage: swift run tools/swiftlint_ast_font_check.swift <target_dir>")
    exit(1)
}
let targetDir = CommandLine.arguments[1]
let fm = FileManager.default
let enumerator = fm.enumerator(atPath: targetDir)
while let file = enumerator?.nextObject() as? String {
    if file.hasSuffix(".swift") {
        checkFonts(in: targetDir + "/" + file)
    }
}
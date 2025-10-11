# Cursor Swift拡張 トラブルシューティングガイド

このドキュメントは、CursorエディタでSwiftUI開発時によく発生する問題と解決策をまとめています。

## 🚨 よくある症状

### 症状1: 赤い波線エラー（コンパイルは成功）
- `@EnvironmentObject`の型が未解決として表示される
- `SomeManager.shared`などの共有インスタンスに赤線が表示される
- `@Published` + `didSet`の組み合わせでエラー表示
- 新しいモジュール追加後にエラーが大量発生

### 症状2: コード補完が機能しない
- SwiftUIのProperty Wrapperで補完が効かない
- フレームワークの型が認識されない
- プロジェクト内の型定義が見つからない

## 🛠 解決手順

### **Step 1: Swift Language Serverの再起動**
```
1. Command Palette (⌘+Shift+P) を開く
2. "Swift: Restart Language Server" を実行
3. 2-3分待つ（大きなプロジェクトの場合）
```

### **Step 2: LSPログの確認**
```
1. Command Palette (⌘+Shift+P) を開く
2. "Swift: Show Language Server Logs" を実行
3. エラーメッセージを確認
```

### **Step 3: Swift拡張の再インストール（推奨）**
```
1. Cursor → Extensions (⌘+Shift+X)
2. "Swift" を検索
3. 歯車アイコン → "Uninstall" 
4. Cursorを完全終了
5. Cursor再起動
6. Swift拡張を再インストール
7. プロジェクトを開き直す
```

### **Step 4: プロジェクトキャッシュのクリア**
```bash
# DerivedDataの削除
rm -rf ~/Library/Developer/Xcode/DerivedData

# Cursorキャッシュの削除
rm -rf ~/.cursor/extensions/*/cache/
rm -rf ~/.cursor/logs/
```

## 📋 大きなモジュール追加時の推奨手順

新しいSwiftファイル群やモジュールを追加する際の手順：

### **事前準備**
1. 変更前にプロジェクトが正常に動作することを確認
2. 可能であれば段階的に小さなファイルから追加

### **追加後の手順**
1. 新しいファイル群を追加
2. **即座に** `Swift: Restart Language Server` を実行
3. 3-5分待機（解析完了を待つ）
4. まだエラーが表示される場合 → **Swift拡張を再インストール**

## ⚙️ .cursor.json 設定例

プロジェクトルートに以下の設定ファイルを配置：

```json
{
  "experimental": {
    "lsp": {
      "semanticTokens": false,
      "xcodeWorkspacePath": "TsukiUsagi.xcodeproj"
    }
  },
  "swift": {
    "lsp": {
      "serverPath": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
      "serverArguments": ["--log-level", "error"]
    }
  },
  "extensions": {
    "swift": {
      "diagnostics": {
        "enable": true
      }
    }
  }
}
```

## 🔍 よくある原因と対策

### **Property Wrapper関連のエラー**

**原因**: `@Published` + `didSet` の組み合わせをLSPが正しく解析できない

**対策**: 以下のパターンに変更
```swift
// 🚫 LSPが混乱するパターン
@Published var value: Bool {
    didSet { /* logic */ }
}

// ✅ 推奨パターン
@Published private var _value: Bool
var value: Bool {
    get { _value }
    set {
        _value = newValue
        // logic here
    }
}
```

### **モジュール間参照のエラー**

**原因**: 新しいモジュール追加時にLSPの依存関係マップが更新されない

**対策**: 
1. Swift拡張の再インストール（最も効果的）
2. プロジェクト全体のクリーンビルド

## 📈 パフォーマンス改善

### **大きなプロジェクトでの推奨設定**

```json
{
  "swift": {
    "lsp": {
      "serverArguments": [
        "--log-level", "error",
        "--index-store-path", ".build/debug/index/store"
      ]
    }
  }
}
```

### **不要な診断を無効化**
```json
{
  "extensions": {
    "swift": {
      "diagnostics": {
        "enable": false
      }
    }
  }
}
```

## ⚡ 緊急時のクイックフィックス

### **5分以内で解決したい場合**
1. **Swift拡張の再インストール**（最優先）
2. Cursor完全再起動
3. プロジェクトフォルダを開き直し

### **開発を継続したい場合**
- エラー表示を無視してXcodeでビルド確認
- Cursor + Xcode の併用開発
- LSP診断を一時的に無効化

## 📞 サポート・報告

### **改善要求の報告先**
- [Cursor GitHub Issues](https://github.com/getcursor/cursor/issues)
- Swift関連のissueには "swift", "lsp", "sourcekit" タグを付ける

### **有用なログ情報**
問題報告時には以下を含める：
- Swift拡張のバージョン
- Cursorのバージョン
- macOSバージョン
- Xcodeバージョン
- LSPログの関連部分

---

## 📝 更新履歴

- **2025-01-27**: 初版作成
- TsukiUsagiプロジェクトでの実際のトラブル事例をベースに作成

---

> **💡 重要**: SwiftUIプロジェクトでCursorを使用する場合、Swift拡張の再インストールは**定期メンテナンス**として考えることを推奨します。特に大きなモジュール追加時は予防的に実行することで、開発効率を大幅に改善できます。
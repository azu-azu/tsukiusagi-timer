# TsukiUsagi ドキュメント

このディレクトリには、TsukiUsagiプロジェクトの開発・運用に関するドキュメントが含まれています。

---

## あなたは今どれを知りたい？

| 目的 | ドキュメント |
|------|-------------|
| 🧠 なぜこの設計なのか | [`_arch-guidelines.md`](./_arch-guidelines.md) |
| 🏛 設計判断の理由を知りたい | [`architecture/adrs/`](./architecture/adrs/) |
| 🛠 実装方法を知りたい | [`implementation/`](./implementation/) |
| 🧪 運用・テスト手順 | [`runbook/`](./runbook/) |
| 📊 過去の作業記録・修正内容 | [`report/`](./report/) |
| 📜 リリース履歴 | [`releases/`](./releases/) |

### ドキュメント階層

```
思想 (_arch-philosophy)
      ↓
意思決定 (_adr-)
      ↓
実装 (_guide-)
      ↓
運用 (_runbook-)
```

---

## 🗂️ Docs Naming Rules（Fujiko構造版）

### 🧭 命名フォーマット

```
[_prefix]-[main-topic].md
```

### ✅ Prefix一覧（カテゴリ別）

| Prefix       | レイヤー     | 意味・役割             | 例                                                   |
| ------------ | -------- | ----------------- | --------------------------------------------------- |
| `_arch-`     | 思想層（最上位） | 設計思想・原則・全体方針      | `_arch-guidelines.md`                               |
| `_adr-`      | 意思決定層    | アーキテクチャ決定記録（ADR）  | `_adr-history-sync-save.md`                         |
| `_guide-`    | 実行層（2番目） | 操作手順・実装ガイド・実務ノウハウ | `_guide-keyboard.md`, `_guide-font-installation.md` |
| `_runbook-`  | 運用手順層    | 運用・テスト・デバッグ手順     | `_runbook-timer-ops-and-tests.md`                   |
| `structure-` | 設計構造層    | フォルダ構成・設計ルール・命名体系 | `structure-directory.md`, `structure-guidelines.md` |
| `changelog-` | 変更履歴層    | 機能別・モジュール別の変更履歴   | `changelog-timer.md`                                |
| `lint-`      | 例外・ルール層  | コード規約や例外設定        | `lint-exceptions.md`                                |
| `report-`    | 報告層      | 作業記録・移行レポート・不具合分析 | `report-history-sync-save.md`                       |
| `README.md`  | 説明層（特例）  | フォルダ全体の概要         | `README.md`（プレフィックスなし）                              |

---

## 📚 **ファイル命名スタイル共通ルール**

| ルール                                    | 内容                                                          |
| -------------------------------------- | ----------------------------------------------------------- |
| 区切りは **ハイフン（-）**                       | 例：`_guide-keyboard.md` ✅ ／ `guide_keyboard.md` ❌            |
| すべて **小文字**                            | 例：`structure-guidelines.md` ✅ ／ `Structure-Guidelines.md` ❌ |
| 意味の中心は **英単語2〜3個以内**                   | 冗長な説明語は避け、簡潔に                                               |
| 英単語順は「カテゴリ → 対象」                       | `guide-keyboard`（ガイド／キーボード）                                 |
| 1ファイル名の語数は **最大4トークン**                 | 例：`_guide-timer-fade-impl.md` まで                            |
| 文字種は `[a-z0-9-_.]` のみ                  | 全角文字・スペース禁止、連続ハイフン（`--`）禁止                                  |
| 日付・バージョンは **必要時のみ末尾に**                 | 日付：`-20251110`（YYYYMMDD）、バージョン：`-v1-1`（ピリオド避け、ハイフンで）       |
| 分野接頭辞の使用を推奨                            | 例：`timer-`、`history-`、`streak-` など機能領域を明示                   |
| 特殊優先順序：`_arch-` → `_adr-` → `_guide-` | 上に並ぶ順で意味的階層を表現する                                            |

---

## 📚 ドキュメント一覧

### 🏛️ 設計思想・アーキテクチャ
- [`_arch-guidelines.md`](./_arch-guidelines.md) - アーキテクチャガイドライン・設計原則

### 🎯 アーキテクチャ決定記録（ADR）
- [`architecture/adrs/_adr-0001-data-sync-strategy.md`](./architecture/adrs/_adr-0001-data-sync-strategy.md) - データ同期戦略（Export/Import → CloudKit ロードマップ）

### 🔧 実装ガイド・手順書
- [`implementation/_guide-font.md`](./implementation/_guide-font.md) - フォント使用ガイドライン
- [`implementation/_guide-font-installation.md`](./implementation/_guide-font-installation.md) - Nunitoフォントのインストール手順
- [`implementation/_guide-keyboard.md`](./implementation/_guide-keyboard.md) - キーボード操作ガイドライン
- [`implementation/_guide-notifications-fg-bg.md`](./implementation/_guide-notifications-fg-bg.md) - フォアグラウンド・バックグラウンド通知ガイド
- [`implementation/_guide-quiet-moon-animation.md`](./implementation/_guide-quiet-moon-animation.md) - Quiet Moon状態からのSTART時アニメーション不発火問題の修正ガイド
- [`implementation/_guide-copy-classification.md`](./implementation/_guide-copy-classification.md) - コピー分類ガイド
- [`implementation/_guide-daily-reflection.md`](./implementation/_guide-daily-reflection.md) - 日次振り返り機能ガイド
- [`implementation/_guide-edit-icon-semantics.md`](./implementation/_guide-edit-icon-semantics.md) - 編集アイコンセマンティクス

### 🏗️ 構造・設計ルール
- [`structure-directory.md`](./structure-directory.md) - プロジェクトディレクトリ構造
- [`structure-guidelines.md`](./structure-guidelines.md) - コード構造ガイドライン

### 📖 運用・テスト手順書（Runbook）
- `runbook/_runbook-*.md` - 運用手順、テスト手順、デバッグ手順を記録
- *(今後追加予定)*

### ⚙️ 設定・例外・ルール
- [`lint-exceptions.md`](./lint-exceptions.md) - SwiftLint例外設定

### 📜 変更履歴（Changelog）
- `changelog/changelog-*.md` - 機能別・モジュール別の変更履歴を記録
- *(今後追加予定)*

### 📊 報告・記録
- [`report/report-history-sync-save.md`](./report/report-history-sync-save.md) - History同期保存移行レポート（データロス防止）★最新
- [`report/report-task-terminology-migration.md`](./report/report-task-terminology-migration.md) - Task用語移行レポート
- [`report/report-timer-initial-display-fix.md`](./report/report-timer-initial-display-fix.md) - タイマー初期表示修正レポート

### 🔧 トラブルシューティング・問題分析
- [`report/trouble-cursor-swift.md`](./report/trouble-cursor-swift.md) - Cursor Swift拡張のトラブルシューティング

### 📜 リリース履歴
- [`releases/v1.2.1_2025-11-06_bug-fixes.md`](./releases/v1.2.1_2025-11-06_bug-fixes.md) - v1.2.1 バグ修正
- [`releases/v1.2.0_2025-10-31_live-activity-notification-update.md`](./releases/v1.2.0_2025-10-31_live-activity-notification-update.md) - v1.2.0 Live Activity更新
- [`releases/v1.1.0_2025-10-19_architectural-refinement.md`](./releases/v1.1.0_2025-10-19_architectural-refinement.md) - v1.1.0 アーキテクチャ改善

---

## 📝 ドキュメント作成・更新ルール

### **ファイル命名規則（Fujiko構造版）**
- `_arch-*.md` - 設計思想・アーキテクチャガイドライン
- `_adr-*.md` - アーキテクチャ決定記録（ADR: Architecture Decision Records）
- `_guide-*.md` - 実装手順・操作ガイド（`implementation/` に配置）
- `_runbook-*.md` - 運用・テスト・デバッグ手順書（`runbook/` に配置）
- `structure-*.md` - 構造・設計ルール
- `changelog-*.md` - 機能別・モジュール別の変更履歴（`changelog/` に配置）
- `lint-*.md` - コード規約・例外設定
- `report-*.md` - 作業記録・移行レポート・不具合分析（`report/` に配置）
- `README.md` - フォルダ概要（プレフィックスなし）

### **ディレクトリ構造**
```
Docs/
├── README.md                    # このファイル
├── _arch-guidelines.md          # 設計思想（ルート）
├── structure-*.md               # 構造ルール（ルート）
├── lint-exceptions.md           # Lint例外（ルート）
├── architecture/                # アーキテクチャ関連
│   └── adrs/                    # ADR（アーキテクチャ決定記録）
│       └── _adr-*.md
├── implementation/              # 実装ガイド
│   └── _guide-*.md
├── report/                      # 報告・不具合分析
│   └── report-*.md
├── runbook/                     # 運用・テスト手順
│   └── _runbook-*.md
├── changelog/                   # 変更履歴
│   └── changelog-*.md
└── releases/                    # リリースノート
    └── v*.md
```

### **更新時の注意**
1. 各ドキュメントの「更新履歴」セクションを必ず更新
2. このREADMEの「ドキュメント一覧」も併せて更新
3. 画像やコードサンプルは相対パスで参照
4. **Fujiko構造の命名ルール**に従ってファイル名を決定

### **コミット番号の記載方法**
ドキュメント内で関連するコミットを参照する際は、以下の形式を使用：

- **単一コミット**: ``Commit: `<hash>` - "<commit message>"``
  - 例: ``Commit: `ed3d217` - "Fix timer display issue: ensure initial value shows for full second"``
- **複数コミット**: リスト形式で記載
  - 例:
    ```markdown
    ## 🔗 関連コミット
    - Commit: `ed3d217` - "Fix timer display issue: ensure initial value shows for full second"
    - Commit: `a521704` - "Add report documenting timer initial display fix"
    ```

**記載場所**:
- `report-*.md`: ドキュメント末尾の「関連コミット」セクションに主要なコミットを記載
- `releases/*.md`: 変更統計セクションにコミット数を記載
- `_guide-*.md`: 必要に応じて関連コミットを記載

---

## 🔗 関連リンク

### **プロジェクト情報**
- [メインリポジトリ](../../) - プロジェクトルート
- [ソースコード](../) - アプリケーションコード

### **外部リソース**
- [SwiftUI公式ドキュメント](https://developer.apple.com/documentation/swiftui/)

---

**💡 ヒント**: 新しいドキュメントを追加した際は、このREADMEも忘れずに更新してください！
**🏗️ Fujiko構造**: ファイル名で意味的階層を表現し、「読む順序 = 理解の順序」を実現しています。

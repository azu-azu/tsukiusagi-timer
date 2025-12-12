# Report: History 同期保存への移行

- **Date**: 2025-12-12
- **Status**: Completed
- **Severity**: High
- **Branch**: `fix/history-sync-save`

---

## 問題の説明

**症状**: セッション終了直後にアプリがクラッシュした場合、履歴データが失われる可能性がある

**根本原因**:
- `HistoryStore.save()` が非同期（`DispatchQueue.global(qos: .utility).async`）で実行されていた
- 書き込み完了前にアプリが終了すると、データがファイルに書き込まれない
- エラーが `try?` で握りつぶされており、失敗を検知できない

**影響範囲**:
- セッション履歴の消失
- ユーザーの集中記録が失われる「データ消えた」レビュー直行リスク

---

## 設計原則

### 永続化の責務分離

| コンポーネント | 永続化方式 | 用途 |
|---------------|-----------|------|
| **HistoryStore** | File (JSON) | セッション履歴・振り返り |
| **SessionManager** | UserDefaults | セッション定義 |
| **StreakManager** | UserDefaults | ストリーク・XP |
| **TimerPersistenceManager** | @AppStorage | タイマー状態 |

### 同期保存を使うべきタイミング

| タイミング | 理由 |
|-----------|------|
| セッション終了時 | ユーザーにとって最も重要なデータ |
| メモ更新時 | ユーザーが明示的に保存操作を行った |
| アプリがバックグラウンドに入る時 | OSによる強制終了に備える |

---

## 修正内容

### Fix 1: HistoryStore に同期保存メソッド追加

**対象**: `HistoryStore.swift`

```swift
/// 同期的に保存する（セッション終了など重要なタイミング用）
///
/// - Note: This method is not thread-safe. Call from a single thread (typically main) only.
/// - Throws: Encoding or file write errors
func saveSync(_ snapshot: HistorySnapshot) throws {
    let payload = PersistedHistory(
        migrationVersion: snapshot.migrationVersion,
        sessions: snapshot.sessions,
        reflections: Array(snapshot.reflections.values)
    )
    let encoded = try encoder.encode(payload)
    try encoded.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
}
```

**設計意図**:
- 同期的に完了を待つことで、呼び出し側は保存完了を保証できる
- `.atomic` オプションで中途半端な書き込みを防止
- スレッドセーフではないことを明示（doc comment）

---

### Fix 2: HistoryViewModel で同期保存を使用

**対象**: `HistoryViewModel.swift`

```swift
func save() {
    saveRetryWorkItem?.cancel()
    let snapshotReflections = reflectionsByDay
    let snapshot = HistorySnapshot(
        migrationVersion: max(migrationVersion, 1),
        sessions: history,
        reflections: snapshotReflections
    )

    do {
        try store.saveSync(snapshot)
        saveRetryAttempts = 0
        migrationVersion = max(migrationVersion, 1)
        markReflectionsAsSaved(snapshotReflections)
        isSavingReflections = reflectionsByDay.values.contains { $0.isPendingSave }
        reflectionSaveError = nil
    } catch {
        #if DEBUG
        print("[history_save_failed] \(error.localizedDescription)")
        #endif
        reflectionSaveError = error
        NotificationCenter.default.post(name: .historySaveFailed, object: error)
        scheduleHistorySaveRetry()
        isSavingReflections = reflectionsByDay.values.contains { $0.isPendingSave }
    }
}
```

**設計意図**:
- 非同期コールバックを排除し、シンプルな同期処理に
- エラー時は明示的にログ出力 + 通知 + リトライスケジュール

---

### Fix 3: Notification.Name の型安全化

**対象**: `HistoryViewModel.swift`

```swift
extension Notification.Name {
    static let historySaveFailed = Notification.Name("HistorySaveFailed")
    static let historySaveRetrying = Notification.Name("HistorySaveRetrying")
    static let historySaveGaveUp = Notification.Name("HistorySaveGaveUp")
}
```

**設計意図**:
- 文字列リテラルの散在を防止
- タイポによるバグを型システムで防ぐ

---

### Fix 4: エラーログの統一

**対象**: `StreakManager.swift`, `SessionManager.swift`

```swift
// StreakManager.swift
private func save() {
    do {
        let data = try JSONEncoder().encode(streakData)
        userDefaults.set(data, forKey: streakDataKey)
    } catch {
        #if DEBUG
        print("[streak_save_failed] \(error.localizedDescription)")
        #endif
    }
}

// SessionManager.swift
internal func save() {
    let allSessionEntries = Array(sessionDatabase.values)
    do {
        let data = try JSONEncoder().encode(allSessionEntries)
        UserDefaults.standard.set(data, forKey: "allSessionEntriesV3")
    } catch {
        #if DEBUG
        print("[session_save_failed] \(error.localizedDescription)")
        #endif
    }
}
```

**設計意図**:
- `try?` による silent failure を排除
- 全 Manager で同じパターンを適用し、一貫性を確保
- ログタグ（`[xxx_save_failed]`）で検索・フィルタリング可能に

---

### Fix 5: バックグラウンド遷移時の保存

**対象**: `ContentView.swift`

```swift
.onReceive(
    NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
) { _ in
    timerVM.appDidEnterBackground()
    historyVM.save()  // 同期保存でデータ保護
}
```

**設計意図**:
- ホームボタン押下やスリープ時にデータを確実に保存
- 「普通にアプリを閉じた」ケースをカバー

---

## 修正ファイル一覧

| ファイル | 変更内容 |
|----------|----------|
| `HistoryStore.swift` | `saveSync()` メソッド追加、旧 `save()` に deprecated 付与 |
| `HistoryViewModel.swift` | 同期保存に切り替え、`Notification.Name` extension 追加 |
| `StreakManager.swift` | `save()` にエラーログ追加 |
| `SessionManager.swift` | `save()` にエラーログ追加 |
| `ContentView.swift` | `didEnterBackground` で同期保存、typed notification 使用 |

---

## 採用しなかった代替案

| 案 | 不採用理由 |
|----|-----------|
| HistoryStore を class 化 + serial queue | 過剰設計。同時アクセスがない設計なので不要 |
| SceneDelegate 追加 | SwiftUI ベースのアプリに UIKit 的な構造を持ち込むのは複雑化 |
| Background Task (`beginBackgroundTask`) | JSON 書き込みは数ミリ秒で完了するため不要 |
| `applicationWillTerminate` 対応 | iOS では呼ばれないケースが多く、費用対効果が低い |

---

## テスト項目

| テスト内容 | 期待結果 |
|-----------|----------|
| セッション終了 → 即ホーム画面 | 履歴が保存されている |
| メモ入力 → アプリ強制終了 | メモが保存されている |
| 複数セッション連続実行 | 全て履歴に記録 |
| 機内モード中のセッション | 正常に保存 |

---

## 教訓 / Lessons Learned

1. **非同期保存は「いつ終わるか分からない」**
   - ユーザーにとって重要なデータは同期保存で確実にコミット

2. **`try?` は「静かな爆弾」**
   - エラーを握りつぶすと、問題発生時に原因追跡が不可能
   - 最低限ログは残す

3. **過剰設計を避ける**
   - queue / class化 / Background Task は「今の規模では不要」
   - 問題が残れば段階的に強化

4. **世界観と実装の整合性**
   - TsukiUsagi は「時間・習慣・静けさ」を扱うアプリ
   - 履歴の保存が不確実なのは世界観に反する

---

## 関連コミット

- Commit: `8a7f4af` - "Fix data loss risk: switch to synchronous save for History"

---

## 関連ドキュメント

- [`_arch-guidelines.md`](../_arch-guidelines.md) - アーキテクチャガイドライン
- [`structure-guidelines.md`](../structure-guidelines.md) - コード構造ガイドライン

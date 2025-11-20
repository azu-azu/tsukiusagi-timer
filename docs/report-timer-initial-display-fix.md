# タイマー初期表示問題の修正まとめ

## 📋 問題の概要

### 症状
- **通常時**: タイマースタート時に最初の分数が1秒進んだところからスタートする
- **Quiet Cosmos経路**: 特に顕著で、初期値が一瞬しか表示されず、すぐに1秒減った値になる

### 期待される動作
- タイマースタート時、最初に表示される分数はデフォルト値（設定値）のまま
- その値が**きっちり1秒間**表示された後、1秒ずつ減っていく

---

## 🔍 根本原因の分析

### 1. 即座の`tick()`呼び出しによる初期値の減算

**問題箇所**: `TimerEngine.start()`

```swift
// 修正前
func start(seconds: Int) {
    // ...
    endAt = Date().addingTimeInterval(TimeInterval(seconds))
    scheduleTimer()
    tick() // ← 即座に呼ばれるため、初期値が1秒減る
}
```

**原因**:
- `tick()`が`endAt.timeIntervalSinceNow`を計算する際、`endAt`設定直後のわずかな時間経過が反映される
- `floor()`による切り捨てで、場合によっては1秒減った値になる

### 2. 秒境界の不一致（SOTの分離）

**問題箇所**: `TimerViewModel+SessionControl.swift`

```swift
// 修正前
// Engine側
endAt = ceil(now.timeIntervalSince1970) + seconds  // 秒境界にアライン

// SessionManager側
endAt = dateProvider.now() + seconds  // 生のnow（非アライン）
```

**原因**:
- Engineは秒境界にアラインした`endAt`を使用
- SessionManagerは生の`now`ベースの`endAt`を使用
- Quiet Cosmos経路で`reestablishBindings()`後に、Session側の`endAt`ベースの購読が走り、異なる境界の値で初期表示を上書き

### 3. `floor()`による2秒飛び

**問題箇所**: `TimerEngine.tick()`

```swift
// 修正前
let remain = max(0, Int(floor(endAt.timeIntervalSinceNow)))
```

**原因**:
- 初回tickが1.01秒遅れた場合、`floor(seconds - 1.01) = seconds - 2`となり、2秒飛ぶ

### 4. 購読の不完全な再確立

**問題箇所**: `TimerViewModel.reestablishBindings()`

```swift
// 修正前
func reestablishBindings() {
    // アニメーション購読のみ再確立
    // stateManagerの購読が失われたまま
}
```

**原因**:
- `performCompleteStateReset()`で`cancellables.removeAll()`により全購読が削除される
- `reestablishBindings()`でアニメーション購読のみ再確立されていた
- `stateManager.$timeRemaining`などの購読が失われ、UIバインディングが正しく機能しない

### 5. 前回設定値の残留

**問題箇所**: `TimerViewModel.performCompleteStateReset()`

**原因**:
- `stateManager.timeRemaining`が明示的に0にリセットされていなかった
- 前回のセッションの設定値（例：20:00）が残り、Quiet Cosmosからの再スタート時に一瞬表示される

### 6. ゴーストtickの発生

**原因**:
- Quiet Cosmosからの再スタート時、RunLoopに乗った古いタイマーのクロージャが遅れて実行される
- `stop()`で`isRunning = false`にしても、古いクロージャ自体は呼ばれる可能性がある

---

## ✅ 解決策の実装

### 1. 秒境界アラインの実装

**変更**: `TimerEngine.start()`, `resume()`, `reset()`

```swift
// 修正後
let now = Date()
let alignedStart = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970))
endAt = alignedStart.addingTimeInterval(TimeInterval(seconds))
```

**効果**: EngineとSessionManagerで同じ秒境界を使用し、SOTを統一

### 2. 単調時計ベースのdisplay gate

**変更**: `TimerEngine`に`displayGateUptime`を追加

```swift
// 初回減算の猶予（必ず1秒見せる）※単調時計で管理
let currentUptime = ProcessInfo.processInfo.systemUptime
displayGateUptime = currentUptime + 1.0

// tick()内でチェック
if let gate = displayGateUptime, ProcessInfo.processInfo.systemUptime < gate {
    return  // まだ1秒経過していないので、何も更新しない
}
```

**効果**:
- 壁時計（`Date()`）の影響を受けない単調時計を使用
- `onTick?(seconds)`呼び出しから1秒間は確実に減算をブロック

### 3. tick epochによるゴーストtick無視

**変更**: `TimerEngine`に`tickEpoch`を追加

```swift
private var tickEpoch: UInt64 = 0

private func scheduleTimer(firstFireAt: Date? = nil) {
    tickEpoch &+= 1
    let myEpoch = tickEpoch
    // ...
    Timer(...) { [weak self] _ in
        guard let self, self.tickEpoch == myEpoch else { return }
        self.tick()
    }
}
```

**効果**: 古いタイマーのクロージャが実行されても、世代が異なれば無視される

### 4. `floor()`から`ceil()`への変更

**変更**: `TimerEngine.tick()`

```swift
// 修正後
let remain = max(0, Int(ceil(endAt.timeIntervalSinceNow)))
```

**効果**: 遅延tickでも2秒飛びが発生しない

### 5. 即座の`tick()`呼び出しを削除

**変更**: `TimerEngine.start()`, `resume()`, `reset()`

```swift
// 修正後
onTick?(seconds)  // 初期値のみ表示
// tick()は呼ばない（1秒後のタイマー更新から開始）
```

**効果**: 初期値がそのまま表示される

### 6. 初回発火時刻の制御

**変更**: `TimerEngine.scheduleTimer()`

```swift
// delayが0に近い場合、最小1.0秒を確保
if delay < 1.0 {
    delay = 1.0
}
```

**効果**: `displayGateUptime`より前にタイマーが発火しないことを保証

### 7. SessionManager側の`endAt`も秒境界にアライン

**変更**: `TimerViewModel+SessionControl.swift`

```swift
// startFromQuietMoon(), startTimerNormalFlow(), resumeTimer()
let now = dateProvider.now()
let alignedStart = Date(timeIntervalSince1970: ceil(now.timeIntervalSince1970))
let endAt = alignedStart.addingTimeInterval(TimeInterval(seconds))
sessionManager.setEndAt(endAt)
```

**効果**: EngineとSessionManagerで同じ`endAt`を使用し、境界の不一致を解消

### 8. 購読の完全な再確立

**変更**: `TimerViewModel.reestablishBindings()`

```swift
// 修正後
func reestablishBindings() {
    // stateManagerの購読を再確立
    stateManager.$timeRemaining.assign(to: &$timeRemaining)
    stateManager.$isRunning.assign(to: &$isRunning)
    // ... その他の購読も再確立

    // sessionManagerの購読を再確立
    sessionManager.$startTime.assign(to: &$startTime)
    sessionManager.$endTime.assign(to: &$endTime)

    // アニメーション購読を再確立
    // ...
}
```

**効果**: Quiet Cosmos経路でもUIバインディングが正しく機能

### 9. 前回設定値の明示的なリセット

**変更**: `TimerViewModel.performCompleteStateReset()`

```swift
// 修正後
stateManager.timeRemaining = 0  // 明示的に0にリセット
```

**効果**: 前回の設定値が残らない

### 10. コードの重複削減と整理

**変更**:
- `scheduleChainNotifications()`ヘルパー関数の追加
- `startPulse.send()`の二重送信を削除
- `timeSensitive: isBG ? true : true`を`true`に統一

**効果**: コードの保守性向上

---

## 📊 修正の効果

### Before（修正前）
- タイマースタート時、初期値が一瞬で1秒減る
- Quiet Cosmosからの再スタート時に特に顕著
- 場合によっては2秒飛ぶ

### After（修正後）
- タイマースタート時、初期値がきっちり1秒間表示される
- 1秒経過後、正確に1秒ずつ減っていく
- Quiet Cosmos経路でも通常時と同様に動作

---

## 🎯 設計原則の確立

### Time SOT（Single Source of Truth）
- **走行中の残り秒**: Engineだけが書く（UI/Sessionは読取専用）
- **`endAt`**: Engine & SessionManagerで同じ秒境界を使用

### 表示の1秒保証
- Engine側: 単調時計（`systemUptime`）+ display gate 1.0sで初期1秒を守る
- UIの別ソース（`.timer`系）を同画面に混在させない

### 購読の一意性
- `onTick`はViewModelに一本化（StateManager側からの設定は無し）

---

## 📝 関連ファイル

- `TsukiUsagi/Features/Timer/Services/TimerEngine.swift`
- `TsukiUsagi/Features/Timer/Managers/TimerStateManager.swift`
- `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel.swift`
- `TsukiUsagi/Features/Timer/ViewModels/TimerViewModel+SessionControl.swift`

---

## 🔗 関連コミット

- Commit: `ed3d217` - "Fix timer display issue: ensure initial value shows for full second"

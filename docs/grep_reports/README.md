# grep_reports 運用ルール

## 格納物
- grep結果ログファイル (.log)
- 差分分析メモ (.md)

## ファイル名命名規則
<YYYY-MM-DD>-<調査内容>.log

例:
2025-07-10-font-grep.log

## 保存対象
- grep結果
- 調査メモ
- 差分修正方針

## 注意
- 検索結果には機微情報を含まないよう注意すること。
- 必ずGit管理対象にすること。

# SPM（Swift Package Manager）GUID重複・依存関係エラー対策まとめ

## エラー例
```
Could not compute dependency graph: unable to load transferred PIF:
The workspace contains multiple references with the same GUID 'PACKAGE:...::MAINGROUP'
```

---

## 原因
- **Swift PackageのGUID重複やキャッシュ不整合**
    - パッケージの追加・削除・バージョン変更・Xcodeのバグ・手動編集などで、
      - 古いキャッシュや`Package.resolved`
      - .xcworkspaceや.xcodeprojの内部参照
      が不整合を起こし、同じGUIDが複数箇所で参照される
- **.xcworkspaceと.xcodeprojの両方で同じパッケージを参照している場合**
- **キャッシュやPackage.resolvedの残骸**

---

## 解決手順
1. **Xcodeを完全に終了**
2. **キャッシュ・Package.resolvedの削除**
    ```sh
    rm -rf ~/Library/Developer/Xcode/DerivedData
    rm -rf TsukiUsagi.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/
    rm -rf TsukiUsagi.xcworkspace/xcshareddata/swiftpm/  # あれば
    rm -f TsukiUsagi.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    rm -f TsukiUsagi.xcworkspace/xcshareddata/swiftpm/Package.resolved
    ```
3. **.xcworkspaceが不要なら削除**
4. **Xcodeで「File > Packages > Reset Package Caches」「Resolve Package Versions」実行**
5. **Swift Packagesタブで重複パッケージがないか確認し、片方をRemove**
6. **再ビルド**

---

## 備考
- これで直らない場合は、.xcworkspace/.xcodeprojを新規作成し直すのが最終手段
- プロジェクトのバージョン管理下で`project.pbxproj`や`Package.resolved`のdiffも確認すること

---

> **Kazumiメモ：**
> SPMのGUID重複エラーは「キャッシュ・参照の不整合」が99%。
> キャッシュ削除＆重複パッケージ整理でほぼ解決！

---

# Swiftの#ifスコープトラップ（TimerEngineの初期化バグ）

## 症状
- #if targetEnvironment(simulator) などの条件コンパイル内で let timerEngine = ... と宣言し、外で self.timerEngine = timerEngine すると、timerEngineがスコープ外で未定義となり、self.timerEngineが正しく初期化されない
- Timerが動かない、isRunningがfalseのまま、などのバグが発生

## NG例
```swift
#if targetEnvironment(simulator)
let timerEngine = MockTimerEngine()
#else
let timerEngine = TimerEngine()
#endif
self.timerEngine = timerEngine // ← スコープ外で未定義
```

## OK例（外で宣言→中で代入）
```swift
let timerEngine: TimerEngineable
#if targetEnvironment(simulator)
print("✅ Using MockTimerEngine")
timerEngine = MockTimerEngine()
#else
print("✅ Using TimerEngine")
timerEngine = TimerEngine()
#endif
self.timerEngine = timerEngine
```

## OK例（selfに直接代入）
```swift
#if targetEnvironment(simulator)
print("✅ Using MockTimerEngine")
self.timerEngine = MockTimerEngine()
#else
print("✅ Using TimerEngine")
self.timerEngine = TimerEngine()
#endif
```

## 修正版init例
```swift
init() {
    #if targetEnvironment(simulator)
    print("✅ Using MockTimerEngine")
    self.timerEngine = MockTimerEngine()
    #else
    print("✅ Using TimerEngine")
    self.timerEngine = TimerEngine()
    #endif
    // ...他サービスの初期化...
}
```

## ポイント
- #ifの中でlet宣言→外で使うのはNG
- 外で宣言→中で代入 or selfに直接代入が正解
- スコープ問題を防ぐことでTimerEngineの初期化バグが解消

> **Kazumiメモ：**
> Swiftの条件コンパイルはスコープに注意！外で使う変数は外で宣言しよう。
# Sudoku Loop

Sudoku Loop 是一款以 Flutter 製作的數獨遊戲，主打每日挑戰、快速開局與輕量成長系統。

## 核心特色

- `Daily Challenge`：每天一題固定盤面（同一天所有玩家盤面一致）。
- `Quick Run`：可直接開始 `Easy` / `Medium` 局；`Hard` 目前鎖定。
- 雙輸入模式：`Number` 與 `Notes`（候選數字）。
- 操作工具：`Undo`、`Hint`、`Check`、清除格子。
- 三種錯誤顯示模式：`Instant`、`Check Only`、`Hardcore`（不顯示錯誤）。
- 成長系統：金幣、連續通關（streak）、主題與棋盤皮膚商店。
- 成績與歷程：統計頁（平均、最佳時間、完美局等）與每日日曆。
- 本機持久化：自動保存目前對局、設定、背包與統計資料。

## 獎勵規則

- 初始金幣：`120`
- Quick Run 通關：
  - `Easy`：`+26`
  - `Medium`：`+34`
- Daily Challenge 首次通關（當日第一次）：
  - 基礎：`+52`
  - 連續獎勵：`streak x 2`，上限 `+20`
- 同一天重玩 Daily 不會重複領取每日獎勵。

## 技術實作

- 框架：`Flutter` + `Dart`
- 狀態管理：`provider`
- 本地儲存：`shared_preferences`
- 題目生成：
  - `Generator` 以 seed 建盤
  - `Solver` 驗證唯一解（多解會回退）
  - Daily 使用日期（`yyyyMMdd`）做 deterministic seed

## 專案結構

```text
lib/
  controllers/
    game_controller.dart      # 對局流程、獎勵、存檔、商店行為
  data/
    puzzle_repository.dart    # Quick / Daily 題目來源
  sudoku/
    generator.dart            # 盤面生成
    solver.dart               # 解題與解數量檢查
    difficulty.dart           # 生成難度設定
  models/
    game_session.dart         # 對局狀態
    player_stats.dart         # 玩家統計
    daily_progress.dart       # 每日連續與完成記錄
    skin_catalog.dart         # 主題與棋盤皮膚目錄
  ui/
    pages/                    # Splash/Home/Game/Result/Shop/Stats/Calendar
    widgets/                  # 棋盤、數字鍵盤、底部操作列等
```

## 開發環境

- Flutter SDK（需符合下列 Dart 限制）
- Dart SDK：`>=2.19.0 <3.0.0`

## 安裝與執行

```bash
flutter pub get
flutter run
```

## 測試

```bash
flutter test
```

目前測試涵蓋：

- Solver 的解數計算與非法盤面判定
- Generator 生成題目的唯一解驗證
- PuzzleRepository 的 deterministic 行為（Quick seed / Daily date）
- GameController 的筆記模式、錯誤顯示、提示、獎勵、存檔恢復、商店購買
- App 啟動流程（Splash 首屏）

## 支援平台

此專案為標準 Flutter 多平台結構，可編譯到 Android、iOS、Web、Windows、macOS、Linux。

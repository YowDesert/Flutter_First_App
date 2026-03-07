# Sudoku Loop

一款以 Flutter 製作的數獨遊戲，包含 Daily Challenge、Quick Run、商店換膚、統計與每日打卡日曆。

## 繳交項目對照

| 繳交項目 | 說明 |
| --- | --- |
| App 操作的 gif 或影片 | 已預留 `docs/media/app-demo.gif` 區塊 |
| GitHub 連結 | 已預留連結欄位 |
| 程式注解 | 已整理註解位置與範例 |
| App 畫面截圖 | 已預留多張截圖區塊 |
| 文字說明（問題、解法、心得） | 已整理專章 |
| 重點程式碼講解 | 已整理核心邏輯解說 |
| GitHub README | 本文件即為可直接上傳版本 |

## GitHub 連結

- Repository: `https://github.com/YowDesert/Flutter_First_App_Sudoku`

## App 操作 GIF（預留）

把你的 GIF 檔案放到 `docs/media/app-demo.gif`，README 會自動顯示。

![App Demo GIF](docs/media/app-demo.gif)

<!-- 預留一點空間給你放說明 -->
<br>
<br>

## App 畫面截圖（預留）

把截圖放到 `docs/media/` 後，可直接用以下檔名覆蓋：

- `docs/media/home.png`
- `docs/media/game.png`
- `docs/media/shop.png`
- `docs/media/stats.png`

| 首頁 Home | 遊戲中 Game |
| --- | --- |
| ![Home](docs/media/home.png) | ![Game](docs/media/game.png) |

| 商店 Shop | 統計 Stats |
| --- | --- |
| ![Shop](docs/media/shop.png) | ![Stats](docs/media/stats.png) |

<br>

## 功能特色

- Daily Challenge：每日固定題目，完成可累積連續天數（streak）。
- Quick Run：快速開局（Easy / Medium）。
- 遊戲操作：數字輸入、Notes 模式、Undo、Hint、Check。
- 錯誤模式：Instant、Check Only、Hardcore（不檢查）。
- 經濟系統：通關獲得金幣，可解鎖 Theme / Board Skin。
- 統計系統：總場次、平均時間、最佳時間、完美局數、累積金幣等。
- 本地儲存：使用 `shared_preferences` 保存進度、設定、背包與統計。

## 技術與環境

- Flutter
- Dart
- `provider`（狀態管理）
- `shared_preferences`（本地持久化）

## 專案結構

```text
lib/
  controllers/
    game_controller.dart      # 核心狀態與規則
  data/
    puzzle_repository.dart    # 題庫與每日題目生成
  models/
    game_session.dart         # 遊戲中狀態
    player_stats.dart         # 統計資料
    skin_catalog.dart         # 商店皮膚定義
  sudoku/
    solver.dart               # 解題器
    generator.dart            # 盤面產生器
  ui/
    pages/                    # Splash/Home/Game/Shop/Stats/Result/Calendar
    widgets/                  # Board/NumberPad/BottomActionBar
```

## 安裝與執行

```bash
flutter pub get
flutter run
```

## 測試

```bash
flutter test
```

目前已有測試涵蓋：

- App 啟動流程（Splash）
- `GameController` 核心邏輯（筆記、提示、錯誤模式、每日題一致性、儲存還原、獎勵）
- Sudoku Solver / Generator 基礎行為

## 程式注解

專案目前以語義化命名為主，並在演算法關鍵處保留註解，例如：

- `lib/sudoku/solver.dart`
  - `/// solve board in-place; return true if solved.`
  - `/// count solutions up to [limit]; stops when reached.`

如果要再加強「程式註解」可優先補在以下檔案的核心方法：

- `lib/controllers/game_controller.dart`（獎勵、錯誤模式、Hint 流程）
- `lib/data/puzzle_repository.dart`（daily seed 與盤面轉換）
- `lib/ui/widgets/board_widget.dart`（格子高亮與錯誤視覺）

## 文字說明（問題、解法、開發心得）

### 遇到的問題與解法

1. 每日題目要固定，但不能每天都長一樣  
解法：用日期（yyyyMMdd）建立 deterministic seed，再搭配數字映射與行列重排，保留唯一解且每天固定。

2. 手機版面在小螢幕容易擠壓  
解法：在 `GamePage` 建立 `_GameLayoutMetrics` 與 `_KeypadMetrics`，根據安全區高度與字體縮放動態調整元件尺寸。

3. 遊戲中斷後要能續玩  
解法：`GameSession`、`PlayerStats`、`Inventory`、`Settings` 都序列化到 `shared_preferences`，重新開啟 app 時還原。

### 開發心得

- 把規則集中在 `GameController`，UI 只負責渲染與觸發事件，維護成本明顯降低。
- 先把資料模型定義清楚（session/stats/inventory），後續擴充商店與結果頁會更順。
- 透過測試鎖住關鍵規則（提示、每日題、儲存還原）能避免 UI 改版時造成回歸問題。

## 重點程式碼講解

### 1) 每日題目生成（Deterministic Daily）

- 檔案：`lib/data/puzzle_repository.dart`
- 核心：`dailyChallenge(DateTime date)`
- 作法：
  - 將日期正規化到年月日。
  - 用日期字串轉成整數 seed（`yyyyMMdd`）。
  - 對基底模板做數字映射 + 行列重排，產生每天固定且有變化的盤面。

### 2) 遊戲主流程與獎勵計算

- 檔案：`lib/controllers/game_controller.dart`
- 核心：
  - `inputDigit`, `toggleInputMode`, `undo`, `useHint`, `checkBoard`
  - `_completeSession`, `_calculateReward`
- 作法：
  - 以 `MoveRecord` 實作 undo/redo。
  - 根據錯誤模式更新可見錯誤格。
  - 通關時依模式發獎勵（Quick 固定值，Daily 含 streak bonus）。

### 3) 棋盤視覺與互動狀態

- 檔案：`lib/ui/widgets/board_widget.dart`
- 核心：
  - `_resolveCellBackground`（同列同宮同值/選取/錯誤高亮）
  - `_GridPainter`（粗細宮格線）
  - `_NotesGrid`（候選數字）
- 作法：
  - 透過 `GameController` 的 `selectedIndex`、`visibleErrorIndexes` 即時反映畫面狀態。

## 後續可擴充方向

- 新增 Hard 難度與更多模板題庫。
- 加入雲端排行榜與登入同步。
- 新增教學關卡與新手引導。

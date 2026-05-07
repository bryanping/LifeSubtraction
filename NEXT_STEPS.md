# 下一步：在 Xcode 中只剩 3 件事

我已直接把所有 Swift 檔放進對的資料夾。你的 Xcode 專案使用 **synchronized folders**（Xcode 16+），所以放在 `LifeSubtraction/` 與 `LifeSubtractionWidget/` 內的檔案會自動被各自的 target 編譯，**不需要任何 drag-drop 動作**。

剩下的工作只有 **三件**，全部在 Xcode UI 完成。

---

## 1️⃣ 刪掉重複的 Widget Target

開啟專案後，左側 Project Navigator 點專案根 → Targets 面板會看到你有 **兩個** `LifeSubtractionWidgetExtension`。原因是建立 Widget Extension 的精靈跑了兩次。

- 找出**沒有**綠色實心圖示（或顯示為 grey/inactive）的那個 target → 右鍵 → **Delete**
- 留下「在 Targets 列表中比較完整、有 fileSystemSynchronizedGroups 的那一個」（通常是後建立、ID 是 `A2B7A551…` 的那個）
- 不確定的話：兩個一起刪，再 **File → New → Target → Widget Extension** 重新建一次（取消「Include Configuration Intent」），名稱仍叫 `LifeSubtractionWidget`。

> ⚠️ 重新建之後，Xcode 會再丟一份 `LifeSubtractionWidget.swift` / `LifeSubtractionWidgetBundle.swift` / `LifeSubtractionWidgetControl.swift` / `LifeSubtractionWidgetLiveActivity.swift` 進資料夾，**會把我寫的版本覆蓋掉**。如果發生，把資料夾裡那 4 個 `.swift` 檔都刪掉，再從 git 還原（或回頭請我重貼）。

---

## 2️⃣ 加 App Group Capability — 兩次

### a. 主 App
1. 點專案 → **Targets** 選 `LifeSubtraction`
2. **Signing & Capabilities** → 左上 **+ Capability** → **App Groups**
3. 點 **+** → 新增 `group.com.bryanping.lifesubtraction`（或你自選的字串，**只要全部 target 用同一個就行**）
4. 確保複選框已勾選

### b. Widget Extension
1. **Targets** 選 `LifeSubtractionWidgetExtension`
2. 一樣 **Signing & Capabilities → + → App Groups**
3. 勾選**同一個** `group.com.bryanping.lifesubtraction`

### c. 同步程式裡的字串
打開這兩個檔，把 group ID 字串改成你剛剛實際輸入的那個：

- `LifeSubtraction/Shared/AppConstants.swift` — `static let appGroup = "group.com.yourname.lifesubtraction"`
- `LifeSubtractionWidget/WidgetShared.swift` — 同樣那一行

兩處要 **一字不差**，否則 Widget 讀不到主 App 的資料。

---

## 3️⃣ Build & Run

⌘R 跑模擬器。長按桌面 → 加入 Widget → 拉「人生減法」分類底下兩款 Widget 上來。

主 App 的 Onboarding 一完成（生日 + 預期壽命），Widget 立刻會看到正確數字。

---

## 結構概覽

```
LifeSubtraction.xcodeproj
│
├── LifeSubtraction/                ← 主 App（資料夾自動同步）
│   ├── LifeSubtractionApp.swift
│   ├── ContentView / OverviewView / WeekGridView / ...
│   ├── Models/LifeStore.swift      ← 改用 App Group
│   ├── Services/{Notification,Store}Manager.swift
│   ├── Shared/                     ← AppConstants / LifeMetrics / LifeTheme
│   └── Assets.xcassets             ← 含 AccentTeal（保留供主 App 用）
│
└── LifeSubtractionWidget/          ← Widget Extension（資料夾自動同步）
    ├── LifeSubtractionWidgetBundle.swift   ← 註冊 4 個 widget
    ├── LifeSubtractionWidget.swift          ← 主 widget（剩餘天數）
    ├── LifeProgressWidget.swift             ← 第二個 widget（年/週進度）
    ├── LifeSubtractionWidgetControl.swift   ← iOS 18 控制中心：開 App
    ├── LifeSubtractionWidgetLiveActivity.swift  ← 預留 Live Activity
    ├── WidgetShared.swift          ← AppConstants / LifeMetrics / LifeTheme（自帶副本）
    ├── Info.plist
    └── Assets.xcassets
```

---

## 為什麼有兩份 LifeMetrics / LifeTheme？

`LifeSubtraction/Shared/` 與 `LifeSubtractionWidget/WidgetShared.swift` 內容幾乎相同。這是刻意的：Xcode 16 的同步資料夾系統**不能讓一個資料夾自動被兩個 target 收編**。要嘛手動勾 Target Membership（我做不到，因為那是 Xcode UI 的設定），要嘛複製檔案（我做了）。

未來你想改主色或新增欄位，記得**兩處都改**。註解寫在 `WidgetShared.swift` 第 6 行有提醒。

---

## Apple Watch App（之後想做）

我之前已經寫好 watch App 的 Swift 檔（在 `LifeSubtractionWatch Watch App/` 與 `LifeSubtractionWatchWidget/` 兩個資料夾），但你的專案目前還沒建立這兩個 target。要啟用：

1. **File → New → Target → watchOS App for iOS App**，命名 `LifeSubtractionWatch`，**勾**「Include Complication」。
2. Xcode 會生成新資料夾，自動同步到 watch target。
3. 把我寫好的 Swift 檔（從 `LifeSubtractionWatch Watch App/`）複製進新資料夾，覆蓋 Xcode 的範本。
4. 同樣的 App Group 步驟做兩次（watch App + watch Widget）。

不急做的話，現在 iOS App + iOS Widget 已經完整可用。

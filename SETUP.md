# 人生減法 — 升級接入指南

這次更新涵蓋四件事：

1. **UI 升級**（OverviewView / WeekGridView / CountdownView / OnboardingView / TabBar）
2. **WeekGridView 重設計**：已過格點 → 文字摘要 + 整體進度條；新增「當前年/週」進度條
3. **WidgetKit 主畫面小工具**（兩款 Widget × 三種尺寸 + Lock Screen）
4. **Apple Watch App + 錶面 Complication**

下面是把新檔案接入 Xcode 專案的完整步驟。

---

## 一、新增的檔案結構

```
LifeSubtraction/
├── LifeSubtraction/
│   ├── Shared/                        ← 新增。四個 target 共用
│   │   ├── AppConstants.swift
│   │   ├── LifeMetrics.swift
│   │   ├── LifeTheme.swift
│   │   └── LifeWidgetProvider.swift   ← iOS / watchOS Widget 都引用
│   ├── Models/LifeStore.swift         ← 已改寫（改用 App Group）
│   ├── Views/                         ← 全部 UI 升級
│   └── LifeSubtraction.entitlements   ← 新增
│
├── LifeSubtractionWidget/             ← 新增 target（iOS Widget Extension）
│   ├── LifeSubtractionWidgetBundle.swift
│   ├── LifeRemainingWidget.swift
│   ├── LifeProgressWidget.swift
│   ├── Info.plist
│   └── LifeSubtractionWidget.entitlements
│
├── LifeSubtractionWatch Watch App/    ← 新增 target（watchOS App）
│   ├── LifeSubtractionWatchApp.swift
│   ├── WatchRootView.swift
│   ├── WatchOverviewView.swift
│   ├── WatchYearProgressView.swift
│   ├── WatchWeekProgressView.swift
│   ├── WatchReflectionView.swift
│   └── LifeSubtractionWatch.entitlements
│
└── LifeSubtractionWatchWidget/        ← 新增 target（watchOS Widget Extension，Complication）
    ├── LifeSubtractionWatchWidgetBundle.swift
    ├── Info.plist
    └── LifeSubtractionWatchWidget.entitlements
```

---

## 二、Xcode 設定步驟

### Step 1. 在 Xcode 把新檔案加入主 App target

1. 在 Xcode 左側 Project Navigator → 主 App 群組上按右鍵 → **Add Files to "LifeSubtraction"...**
2. 選 `LifeSubtraction/Shared/` 整個資料夾。Target Membership 勾選 **LifeSubtraction**（主 App）。
3. 同樣方式把 `LifeSubtraction.entitlements` 加進來。

### Step 2. 建立 Widget Extension target（iOS 主畫面小工具）

1. **File → New → Target → Widget Extension**
2. Product Name 輸入 `LifeSubtractionWidget`
3. **取消勾選** "Include Configuration Intent"（我們用 Static configuration）
4. 建立完成後，Xcode 會幫你產生一個預設的 `LifeSubtractionWidget.swift`。**刪除**這個檔案。同時請從專案中移除 `LifeSubtractionWidget/LifeWidgetProvider.swift`（我留了一個空殼檔做提示，實際 Provider 已搬到 `Shared/`）。
5. 把我已產生的 `LifeSubtractionWidget/` 內所有 `.swift` 檔（除上一行那個空殼）加入這個 target。
6. 把 `Shared/` 資料夾的三個檔（AppConstants / LifeMetrics / LifeTheme）也勾選 Target Membership = `LifeSubtractionWidget`（一個檔案可以同時屬於多個 target）。
7. 把 `Assets.xcassets` 的 Target Membership 也加上 `LifeSubtractionWidget`，這樣 `Color("AccentTeal")` 才找得到。

### Step 3. 建立 watchOS App target

1. **File → New → Target → watchOS App for iOS App**
2. Product Name 輸入 `LifeSubtractionWatch`
3. **勾選** "Include Notification Scene" 可以不勾，**「Include Complication」可以勾**（Xcode 會多生成一個 Widget Extension target，名為 `LifeSubtractionWatchWidget` ← 這就是我這邊已經寫好的程式所對應的 target）
4. 建立完成後，刪除 Xcode 自動產生的範本檔，改用我提供的：
   - 把 `LifeSubtractionWatch Watch App/` 內所有 `.swift` 檔加入 watchOS App target
   - 把 `LifeSubtractionWatchWidget/` 內所有 `.swift` 加入 watch widget target
5. 同樣把 `Shared/` 三個檔的 Target Membership 加上 **watchOS App** 與 **watchOS Widget**。
6. `Assets.xcassets`（含 `AccentTeal`）也加上 watchOS App / Widget 的 Target Membership，否則顏色會 fallback 為系統藍。
   - 也可以另建一個 watch 專用的 asset catalog，再把 AccentTeal 複製過去。

### Step 4. 三個 target 都加上同一個 App Group

主 App、iOS Widget、watchOS App、watchOS Widget — **四個 target** 都需要：

1. 選該 target → **Signing & Capabilities** → 左上角 **+ Capability** → 加入 **App Groups**
2. 點 **+** → 新增 `group.com.yourname.lifesubtraction`
3. **每個 target 都要勾選同一個** group

> ⚠️ 我在程式中寫的 group 名稱是 `group.com.yourname.lifesubtraction`，請改成你自己的（例如 `group.com.deamor.lifesubtraction`），然後同步修改：
> - `Shared/AppConstants.swift` 第 9 行的 `appGroup`
> - 四個 `.entitlements` 檔內的 `<string>group.xxx</string>`

### Step 5. Bundle ID 規範

建議命名：

| Target | Bundle ID 範例 |
| --- | --- |
| 主 App | `com.deamor.lifesubtraction` |
| iOS Widget | `com.deamor.lifesubtraction.widget` |
| watchOS App | `com.deamor.lifesubtraction.watchkitapp` |
| watchOS Widget | `com.deamor.lifesubtraction.watchkitapp.widget` |

watchOS App 的 `Info.plist` 中，`WKCompanionAppBundleIdentifier` 必須等於主 App 的 Bundle ID。Xcode 用模板建立 watch target 時會自動寫好。

### Step 6. iOS Deployment Target

- 主 App、Widget：iOS 17+（用了 `containerBackground(for:)`、`#Preview` 等新 API）
- watchOS App：watchOS 10+

如果要支援更舊版本，需要把 Widget 的 `containerBackground` 包進 `if #available`。

---

## 三、本次 UI / 邏輯改動摘要

### WeekGridView（生命週/年）
- **不再畫已過的格點**。已過的時間改用一張卡片描述：「已度過 N 個年頭 / 週」+ 整體進度條。
- 卡片底部新增 **當前那一年 / 當前那一週的進度條**（橘色），告訴使用者「這個格子目前走到哪」。
- 下方格網只顯示「未來」的格子，當前那一格會用左→右進度填充呈現。
- 新增圖例、顏色一致化（azure + warm orange + soft purple）。

### OverviewView
- Hero 區改成漸層卡片，含內嵌進度條。
- StatCard 加入 icon + 細邊框，accent 卡片有強調色。
- CountdownRow 改用「圓形彩色 icon + 數字 + 單位」的標準列格式。

### CountdownView / OnboardingView / ContentView
- 漸層 hero、Capsule 風格按鈕、TabBar 半透明 blur background、Slider 與按鈕陰影。

### LifeStore
- 全部資料改寫到 App Group 共享 UserDefaults，並在資料變動時呼叫 `WidgetCenter.shared.reloadAllTimelines()`。
- 新增 `metrics` 計算屬性，重用 `LifeMetrics`。

### Widget（兩款）
1. **LifeRemainingWidget** — 剩餘天數，支援 small / medium / large + 全部 Lock Screen accessory。
2. **LifeProgressWidget** — 當前年 + 當前週進度，支援 small / medium + accessoryCircular。

### Apple Watch App
- 垂直分頁（VerticalPage TabView）：
  1. 總覽（剩餘天數、週、年、年齡）
  2. 本年進度環
  3. 本週進度環
  4. 今日反思提問（可換題）
- 每分鐘自動 reload。

### Apple Watch 錶面 Complication
- 圓形（環狀「已過 %」）
- 角落（環狀 + label）
- inline / rectangular 三種

---

## 四、常見問題

**Q：執行後 Widget 顯示 0 天剩餘？**
A：表示 App Group 沒共享成功。請確認：①主 App 與 Widget 都加了同一個 App Group；②`AppConstants.appGroup` 的字串和 Capabilities 內的字串一字不差。

**Q：Widget 顏色變成系統藍？**
A：`Color("AccentTeal")` 的 asset 沒被 Widget target 引用。在 `Assets.xcassets` 點 Inspector → Target Membership 也勾上 Widget。

**Q：watchOS 編譯時找不到 `Color("AccentTeal")`？**
A：同上，把 Asset Catalog 的 Target Membership 加上 Watch App / Watch Widget。也可以複製一份 `AccentTeal.colorset` 到 watch 端的 asset catalog。

**Q：StoreManager 編譯錯 "does not conform to ObservableObject"？**
A：上一輪已修。檔案最上面要有 `import Combine`。

**Q：Watch App 一直顯示生日 1995 之類的預設值？**
A：表示 watch 還沒從 App Group 讀到資料。請先在 iPhone 上完成 Onboarding，待 App Group 同步後 watch 就會看到正確數字。

---

完成這些步驟後 ⌘R 跑 iPhone Simulator 應該就看得到新 UI；長按桌面 → + 加入 Widget 就能看到「人生減法」分類底下兩款小工具。

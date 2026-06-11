# 人生減法 — iOS App

## 專案結構

```
LifeSubtractionApp/
├── LifeSubtractionApp.swift      ← App 入口
├── Models/
│   └── LifeStore.swift           ← 資料模型與 UserDefaults 儲存
├── Views/
│   ├── ContentView.swift         ← TabView 主畫面
│   ├── OnboardingView.swift      ← 首次啟動引導
│   ├── OverviewView.swift        ← 總覽（天數、統計、倒數清單）
│   ├── WeekGridView.swift        ← 生命週點陣圖
│   ├── CountdownView.swift       ← 倒數 + 今日反思
│   ├── ValuesView.swift          ← 價值觀日記
│   └── SettingsView.swift        ← 設定
└── Services/
    └── NotificationManager.swift ← 每日推播提醒
```

---

## Xcode 建立步驟

### 1. 建立新專案
- 打開 Xcode → File → New → Project
- 選擇 **iOS App**
- Product Name: `LifeSubtractionApp`
- Interface: **SwiftUI**
- Language: **Swift**
- Bundle Identifier: `com.yourname.lifesubtraction`（之後上架要唯一）

### 2. 加入檔案
- 把所有 `.swift` 檔案拖入 Xcode 對應的 Group
- 注意：刪除 Xcode 自動建立的 `ContentView.swift`，用本專案的替換

### 3. 加入自訂顏色
在 `Assets.xcassets` 新增 Color Set：
- 名稱：`AccentTeal`
- Any Appearance: `#1D9E75`
- Dark: `#5DCAA5`

### 4. Info.plist 設定
加入以下 key（隱私說明，App Review 必要）：
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>每日提醒您反思今天的時間使用</string>
```

### 5. 執行測試
- 選擇模擬器（iPhone 15 Pro 推薦）
- Cmd+R 執行

---

## App Store 上架步驟

### 前置作業
1. **Apple Developer Program** — 需付年費 $99 USD（約 NT$3,200）
   - 前往 https://developer.apple.com/programs/enroll/
   - 個人或公司皆可申請

2. **App Store Connect** — https://appstoreconnect.apple.com
   - 建立新 App
   - 填入 Bundle ID（要與 Xcode 相同）

### Xcode 設定
```
Signing & Capabilities → Team → 選擇你的 Apple Developer 帳號
Bundle Identifier → com.yourname.lifesubtraction
Version → 1.0.0
Build → 1
```

### 截圖尺寸（必填）
需準備以下尺寸截圖：
- iPhone 6.7" (iPhone 14 Plus / 15 Plus)：1290 × 2796
- iPhone 6.5" (iPhone 12/13/14 Pro Max)：1284 × 2778
- iPad 12.9"（若支援 iPad）

用 Xcode 模擬器截圖，或用 Figma 製作宣傳圖。

### Archive & 上傳
1. Xcode → Product → Archive
2. 等待完成後 → Distribute App → App Store Connect
3. 等待 Apple 處理（約 10-30 分鐘）
4. 前往 App Store Connect → 選擇剛上傳的 Build
5. 填寫 App 資訊：
   - 名稱：人生減法
   - 副標題：看見剩餘的時間
   - 描述：（見下方）
   - 類別：Health & Fitness / Lifestyle
   - 隱私政策網址（必填）

### App 描述範本
```
每個人都知道時間有限，卻很少真正感受它。

人生減法把你剩餘的天數攤在你面前——不是為了讓你焦慮，而是為了讓你清醒。

當你看見那個數字，你會更容易問自己：今天，我做了什麼值得的事？

功能：
• 生命倒數——剩餘天數、週數、年數一目了然
• 生命週點陣圖——每個點代表一週，直到你看見自己在哪裡
• 「還剩幾次？」——把時間翻譯成夏天、旅行、與父母的相聚
• 今日反思——每天記錄一件讓未來的你感謝的事
• 價值觀日記——寫下你真正重視的事，讓選擇更清晰
• 每晚提醒——溫和地問你今天過得怎樣

完全本地儲存，不需帳號，不收集任何資料。
```

### 定價建議
- 免費版：個人倒數、1 位家人、基本 Widget
- 一次付費 NT$90：無限家人、年度回顧、匯出/iCloud、進階 Widget + 鎖屏、Watch 進階

---

## 後續功能（v1.1+）

- Widget（主螢幕顯示剩餘天數）→ 用 WidgetKit
- iCloud 同步 → 用 CloudKit
- 年度回顧報告 → ShareSheet 分享圖片
- StoreKit 付費解鎖
- Apple Watch App

---

## 需要幫助？

告訴 Claude：
- "幫我加 WidgetKit 主螢幕小工具"
- "幫我實作 StoreKit 付費功能"
- "幫我做 App Store 截圖設計（Figma）"

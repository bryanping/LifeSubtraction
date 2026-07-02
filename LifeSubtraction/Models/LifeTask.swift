import Foundation

// MARK: - LifeTask
// 輕量版人生待辦，核心是「今天能不能做」的感受。
// 與 LifeGoal 並存：LifeGoal 是大目標（學語言、跑馬拉松），LifeTask 是小事（和媽媽吃頓飯）。

struct LifeTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var category: GoalCategory = .experience
    var estimatedMinutes: Int? // nil = 未設定
    var reminderDate: Date?
    var completedAt: Date?
    var completionNote: String?
    var isStarred: Bool = false
    var isArchived: Bool = false
    var snoozedUntil: Date? // 「改天」：暫時從今日推薦隱藏
    var createdAt: Date = Date()

    // MARK: - Computed

    var isPending: Bool { completedAt == nil && !isArchived }
    var isCompleted: Bool { completedAt != nil }

    /// 今天是否應該出現在推薦中（排除已被 snooze 的）
    var isCurrentlyActive: Bool {
        guard isPending else { return false }
        guard let snooze = snoozedUntil else { return true }
        return Date() >= snooze
    }

    /// 快速任務：一小時內可完成
    var isQuick: Bool {
        guard let mins = estimatedMinutes else { return false }
        return mins <= 60
    }

    var estimatedLabel: String {
        guard let mins = estimatedMinutes else { return "" }
        if mins < 60 { return "\(mins) 分鐘" }
        let h = mins / 60
        let m = mins % 60
        return m == 0 ? "\(h) 小時" : "\(h)h\(m)m"
    }
}

// MARK: - LifeTask Extension: Snooze

extension LifeTask {
    mutating func snoozeForDays(_ days: Int) {
        snoozedUntil = Calendar.current.date(byAdding: .day, value: days, to: Date())
    }

    mutating func complete(note: String? = nil) {
        completedAt = Date()
        completionNote = note
    }
}

// MARK: - EstimatedTime Options

enum EstimatedTime: Int, CaseIterable, Identifiable {
    case fifteenMin = 15
    case thirtyMin = 30
    case oneHour = 60
    case twoHours = 120
    case halfDay = 240
    case fullDay = 480

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fifteenMin: return "15 分鐘"
        case .thirtyMin:  return "30 分鐘"
        case .oneHour:    return "1 小時"
        case .twoHours:   return "2 小時"
        case .halfDay:    return "半天"
        case .fullDay:    return "一整天"
        }
    }
}

// MARK: - TaskRecommender
// 純本地規則引擎，不需要 AI。
// 日後可替換為 AI 排序，介面不變。

struct TaskRecommender {

    /// 今日主推薦（1 件）
    static func primary(from tasks: [LifeTask]) -> LifeTask? {
        scored(from: tasks).first?.task
    }

    /// 次要推薦（最多 N 件，排除 primary）
    static func secondary(from tasks: [LifeTask], primaryId: UUID?, maxCount: Int = 2) -> [LifeTask] {
        scored(from: tasks)
            .filter { $0.task.id != primaryId }
            .prefix(maxCount)
            .map { $0.task }
    }

    // MARK: - Private

    private struct ScoredTask {
        let task: LifeTask
        let score: Double
    }

    private static func scored(from tasks: [LifeTask]) -> [ScoredTask] {
        let active = tasks.filter { $0.isCurrentlyActive }
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1=Sun, 7=Sat
        let isWeekend = weekday == 1 || weekday == 7

        return active
            .map { task -> ScoredTask in
                var score = 0.0

                // 快速任務（一小時內）高優先
                if task.isQuick { score += 3.0 }

                // 釘選任務
                if task.isStarred { score += 2.0 }

                // 提醒日期已過期
                if let reminder = task.reminderDate, reminder < Date() { score += 5.0 }

                // 近期即將到期的提醒
                if let reminder = task.reminderDate {
                    let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: reminder).day ?? 99
                    if daysUntil <= 3 { score += 3.0 }
                    else if daysUntil <= 7 { score += 1.5 }
                }

                // 週末優先家人/體驗
                if isWeekend && (task.category == .family || task.category == .experience) {
                    score += 1.5
                }
                // 平日優先成長/創造
                if !isWeekend && (task.category == .growth || task.category == .creation) {
                    score += 1.0
                }

                // 微隨機：同分時每次略不同（用 task id hash 決定，同一天穩定）
                let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
                let jitter = Double((task.id.hashValue ^ dayOfYear) & 0xFF) / 512.0
                score += jitter

                return ScoredTask(task: task, score: score)
            }
            .sorted { $0.score > $1.score }
    }
}

// MARK: - CategoryContext
// 從用戶的 tasks + goals 推導出「今天最相關的類別」，供語錄和反思問題個人化使用。

enum CategoryContext {
    /// 依優先順序：今日推薦任務類別 → 釘選任務最多類別 → 所有任務最多類別 → 大目標最多類別 → nil
    static func dominant(primaryTask: LifeTask?, allTasks: [LifeTask], goals: [LifeGoal]) -> GoalCategory? {
        if let cat = primaryTask?.category { return cat }

        let starred = allTasks.filter { $0.isStarred && $0.isPending }.map(\.category)
        if let cat = mostCommon(starred) { return cat }

        let active = allTasks.filter { $0.isPending }.map(\.category)
        if let cat = mostCommon(active) { return cat }

        let goalCats = goals.filter { $0.status == .active }.map(\.category)
        if let cat = mostCommon(goalCats) { return cat }

        return nil
    }

    private static func mostCommon(_ items: [GoalCategory]) -> GoalCategory? {
        guard !items.isEmpty else { return nil }
        return Dictionary(grouping: items, by: { $0 })
            .max(by: { $0.value.count < $1.value.count })?.key
    }
}

// MARK: - DailyReminder
// 修改内容 — 依用戶任務/目標主要類別選取對應語錄；同一天同一類別永遠是同一句（穩定性）。

enum DailyReminder {
    /// 客製化版：依用戶清單內容選取對應類別語錄
    static func today(primaryTask: LifeTask?, allTasks: [LifeTask], goals: [LifeGoal]) -> String {
        let category = CategoryContext.dominant(primaryTask: primaryTask, allTasks: allTasks, goals: goals)
        return pickByDay(from: quotes(for: category))
    }

    /// 通用版：不需要 context，供不載入任務的頁面使用
    static func today() -> String {
        pickByDay(from: quotes(for: nil))
    }

    private static func pickByDay(from pool: [String]) -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return pool[dayOfYear % pool.count]
    }

    private static func quotes(for category: GoalCategory?) -> [String] {
        switch category {
        case .family:
            return [
                "今天，找個時間陪陪家人。",
                "想對家人說的話，今天說吧。",
                "家人在的時候，放下手機，好好在一起。",
                "約個時間和父母吃頓飯。",
                "陪伴不需要理由，只需要行動。",
                "今天，跟家人說一句平時沒說出口的話。",
            ]
        case .experience:
            return [
                "清單上有件事一直等你，今天動一下吧。",
                "旅行不需要等到準備好，只需要出發。",
                "今年，把那個地方排進行程裡。",
                "今天，預訂一件你一直「之後再說」的事。",
                "最好的體驗，都是從說走就走那一刻開始的。",
                "把那個地方，從想去改成訂好票。",
            ]
        case .growth:
            return [
                "今天學一件小事，哪怕只有幾分鐘。",
                "進步不是大躍進，是每天往前一步。",
                "今天，往你想成為的那個人靠近一點點。",
                "今天找幾分鐘，讀一頁、寫幾行。",
                "成長是安靜的，但不是不動的。",
                "今天，練習你最想精通的那件事。",
            ]
        case .health:
            return [
                "你的身體每天都在幫你，今天回報它一下。",
                "睡得好、吃得對、動一動，其他事才有意義。",
                "今天，為自己存一點健康。",
                "不需要完美的計畫，只需要今天動一次。",
                "照顧自己，是今天最重要的一件事。",
                "五年後的你，會感謝今天做的選擇。",
            ]
        case .creation:
            return [
                "今天，動手做那件你一直想做的東西。",
                "靈感是動了之後才來的，先動手。",
                "完成一件不完美的作品，勝過無數完美的計畫。",
                "今天，把腦中那個想法輸出一點點。",
                "創作是給自己留下的痕跡。",
                "今天，讓手比腦先動。",
            ]
        case .relationship:
            return [
                "傳一則訊息給那個很久沒聯絡的朋友。",
                "關係需要主動澆水，今天傳個訊息吧。",
                "主動聯繫，勝過等對方先說。",
                "想感謝的那個人，今天跟他說一句吧。",
                "想說的話，現在就說。",
                "今天，告訴一個人他對你有多重要。",
            ]
        case .dream:
            return [
                "今天，讓大夢想往前走一毫米。",
                "夢想不需要完整的計畫，只需要下一步。",
                "你最想實現的那件事，今天可以做什麼？",
                "把「有一天」換成一個具體的日期。",
                "今天，把夢想從清單裡拿出來看一眼。",
                "許多大事，都是從某個普通的今天開始的。",
            ]
        case .contribution:
            return [
                "今天，對某個人做一件小的好事。",
                "幫助不需要偉大，一件小事就夠了。",
                "你的存在，讓誰的日子好過了一點。",
                "今天，做一件不為自己、為別人的事。",
                "貢獻是最持久的快樂來源之一。",
                "你最想改變的那件事，今天邁出一步。",
            ]
        case nil:
            return [
                "今天，是新的開始。",
                "不需要做完所有事，只需要做對的事。",
                "小事也算數。完成一件，勝過計畫十件。",
                "把時間給讓你感到值得的事。",
                "不需要準備好，只需要開始。",
                "忙，不等於前進。",
                "今天，讓最想完成的那件事往前一步。",
                "完成比完美更重要。",
                "時機永遠都在，現在就是。",
                "今天，為未來的你種一顆種子。",
            ]
        }
    }
}

// MARK: - DailyReflectionPrompt
// 修改内容 — 依用戶任務/目標主要類別選取對應反思問題；依星期幾在同類別內輪換。

enum DailyReflectionPrompt {
    /// 客製化版：依用戶清單內容選取對應類別反思問題
    static func today(primaryTask: LifeTask?, allTasks: [LifeTask], goals: [LifeGoal]) -> String {
        let category = CategoryContext.dominant(primaryTask: primaryTask, allTasks: allTasks, goals: goals)
        return pickByWeekday(from: prompts(for: category))
    }

    /// 通用版：依星期幾輪換，不需要 context
    static func today() -> String {
        pickByWeekday(from: prompts(for: nil))
    }

    private static func pickByWeekday(from pool: [String]) -> String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return pool[(weekday - 1) % pool.count]
    }

    private static func prompts(for category: GoalCategory?) -> [String] {
        switch category {
        case .family:
            return [
                "今天和家人有沒有一個讓你想記住的瞬間？",
                "今天你對家人說了什麼，或做了什麼小事？",
                "有沒有一件你想為家人做的事，可以安排在近期？",
                "今天陪伴家人的時候，你有真的在場嗎？",
                "你希望家人記得今天的你是什麼樣子？",
                "今天有沒有聽到家人說的某句話，讓你有點感觸？",
                "今天和家人在一起，有什麼讓你感到溫暖的時刻？",
            ]
        case .experience:
            return [
                "今天有沒有一個新的體驗，哪怕很小？",
                "清單上那件事，今天離它更近了嗎？",
                "今天有什麼讓你感到開心的瞬間？",
                "有沒有一件事，你今天邁出了第一步？",
                "今天你有沒有做了一件平時不常做的事？",
                "如果今年只能完成清單上一件事，你最期待哪件？",
                "今天你有沒有讓自己靠近了一個一直想去的地方？",
            ]
        case .growth:
            return [
                "今天你學到了什麼？",
                "今天有哪個想法，讓你想繼續深入？",
                "你最近在哪個方向上，感覺最有收穫？",
                "今天有沒有一個讓你對自己更了解的發現？",
                "今天你有沒有嘗試了一個不一樣的做法？",
                "你現在的狀態，和你想成為的樣子，有哪些地方已經很像了？",
                "今天讀了什麼、學了什麼、想清楚了什麼？",
            ]
        case .health:
            return [
                "今天你有沒有做了一件讓身體感謝的事？",
                "你今天的能量狀態怎麼樣？是什麼讓它變好的？",
                "有沒有一個讓你感覺輕盈的小習慣，今天做了？",
                "今天你的身體有沒有傳遞什麼訊息給你？",
                "今天吃得好、睡得夠、動了嗎？",
                "有沒有一件對自己好的事，可以安排在今晚做？",
                "今天你有沒有對自己的身體多一點溫柔？",
            ]
        case .creation:
            return [
                "今天你有沒有創造了什麼，哪怕只是一個想法？",
                "那個作品，今天有沒有往前推進一點點？",
                "今天做的過程中，有沒有一個讓你滿意的部分？",
                "今天你有沒有沉浸在創作裡，忘記了時間？",
                "今天你有沒有把腦中的某個東西，輸出到現實裡？",
                "創作的路上，今天感覺比昨天順了一點嗎？",
                "如果有人問你今天做了什麼，你會怎麼介紹？",
            ]
        case .relationship:
            return [
                "今天有沒有一段對話，讓你感到真實的連結？",
                "今天有沒有主動聯繫了一個想念的人？",
                "今天有沒有人讓你感謝他出現在你生命裡？",
                "你最珍視的那段關係，今天有沒有用行動表達？",
                "有沒有一句想說的話，今天說了嗎？",
                "今天你有沒有真的聽進了某個人說的話？",
                "你希望重要的人，今天看到的你是什麼樣子？",
            ]
        case .dream:
            return [
                "今天你的大夢想，有沒有往前走了一步？",
                "有什麼事情，今天感覺比上週更有把握了？",
                "你現在的行動，和你想像中的自己有哪些重疊？",
                "今天有沒有一件小事，讓你覺得方向是對的？",
                "今天你最想多做一點的事是什麼？",
                "你的夢想，今天需要你做的那一步是什麼？",
                "今天有沒有一個讓你覺得「對，就是這個方向」的感受？",
            ]
        case .contribution:
            return [
                "今天你有沒有讓某個人的日子，好過了一點點？",
                "今天做了什麼，讓你覺得自己的存在有意義？",
                "有沒有一件幫助別人的事，讓你也感到快樂？",
                "今天你有沒有說了一句讓別人感到被看見的話？",
                "你最在意的那個問題，今天有沒有往它靠近一點？",
                "今天有沒有人因為你，感覺好一點了？",
                "你希望別人今天記得你的什麼？",
            ]
        case nil:
            return [
                "今天，你做了什麼讓自己感到滿足的事？",
                "今天最值得留下的是哪個瞬間？",
                "今天有沒有做了一件讓你開心的事？",
                "今天有沒有人讓你感到溫暖？",
                "今天你有沒有為自己做一件事？",
                "這週快結束了，還有什麼想在週末完成的？",
                "今天放鬆了嗎？記下一個快樂的細節。",
            ]
        }
    }
}

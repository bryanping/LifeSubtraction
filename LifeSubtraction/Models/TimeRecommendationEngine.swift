import Foundation

enum TimeRecommendationAction: Hashable {
    case addTask(title: String, category: GoalCategory, minutes: Int)
    case openGoal(UUID)
    case none
}

struct TimeRecommendation: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let reason: String
    let category: GoalCategory
    let sourceLabel: String
    let estimatedMinutes: Int?
    let sopSteps: [String]
    let action: TimeRecommendationAction
}

struct TimeRecommendationContext {
    let now: Date
    let metrics: LifeMetrics
    let scope: TimeRecommendationScope
    let goals: [LifeGoal]
    let tasks: [LifeTask]
    let familyMembers: [FamilyMember]
    let batch: Int
}

enum TimeRecommendationScope: Hashable {
    case year
    case month
    case today
}

enum TimeRecommendationEngine {
    static func recommendations(context: TimeRecommendationContext, maxCount: Int = 5) -> [TimeRecommendation] {
        let pool = buildPool(context: context)
        let deduped = dedupe(pool)
        guard !deduped.isEmpty else { return [] }

        let pageSize = max(3, maxCount)
        let start = (context.batch * pageSize) % deduped.count
        let slice = deduped.dropFirst(start).prefix(pageSize)
        if slice.count < pageSize && deduped.count > pageSize {
            return Array(slice) + Array(deduped.prefix(pageSize - slice.count))
        }
        return Array(slice)
    }

    private static func buildPool(context: TimeRecommendationContext) -> [TimeRecommendation] {
        var result: [TimeRecommendation] = []
        let existingTitles = Set(
            context.tasks
                .filter { $0.isPending }
                .map { normalized($0.title) }
        )

        switch context.scope {
        case .year:
            result += yearScopeRecommendations(context: context, existingTitles: existingTitles)
            result += goalNextStepRecommendations(context: context, existingTitles: existingTitles, limit: 3)
            result += ageRecommendations(context: context, existingTitles: existingTitles)

        case .month:
            result += monthScopeRecommendations(context: context, existingTitles: existingTitles)
            result += familyRecommendations(context: context, existingTitles: existingTitles)
            result += goalNextStepRecommendations(context: context, existingTitles: existingTitles, limit: 2)

        case .today:
            result += activeTaskRecommendations(context: context)
            result += timeSlotRecommendations(context: context, existingTitles: existingTitles)
            result += familyRecommendations(context: context, existingTitles: existingTitles)
            result += ageRecommendations(context: context, existingTitles: existingTitles)
            result += goalNextStepRecommendations(context: context, existingTitles: existingTitles, limit: 2)
        }

        return result
    }

    private static func yearScopeRecommendations(
        context: TimeRecommendationContext,
        existingTitles: Set<String>
    ) -> [TimeRecommendation] {
        let daysLeft = max(0, Int(context.metrics.daysRemainingThisYear.rounded()))
        let activeGoals = context.goals.filter { $0.status == .active }
        var result: [TimeRecommendation] = [
            quick(
                "選出今年最想完成的一件事",
                .dream,
                20,
                "",
                "今年視角",
                ["打開你的進行中目標", "只選一件今年最值得推進的事", "寫下本週能做的第一步"]
            ),
            quick(
                "整理今年的家庭回憶",
                .family,
                30,
                "今年還剩 \(daysLeft) 天，適合先保存一段已經發生的回憶。",
                "今年視角",
                ["選 10 張今年的照片", "刪掉重複或模糊照片", "挑 1 張傳給家人"]
            )
        ]

        if activeGoals.isEmpty {
            result.append(quick(
                "建立今年的人生清單",
                .growth,
                20,
                "今年視角下應先決定方向，而不是直接推薦大型計劃。",
                "今年視角",
                ["寫下 3 件今年想完成的事", "刪到只剩 1 件最重要的", "把它拆成第一步"]
            ))
        }

        return result.filter { !existingTitles.contains(normalized($0.title)) }
    }

    private static func monthScopeRecommendations(
        context: TimeRecommendationContext,
        existingTitles: Set<String>
    ) -> [TimeRecommendation] {
        let daysLeft = max(0, Int(context.metrics.daysRemainingThisMonth.rounded()))
        let result = [
            quick(
                "安排本月一次家人時間",
                .family,
                15,
                "",
                "本月視角",
                ["先選一位重要的人", "傳訊息問本月哪天方便", "只把時間約下來"]
            ),
            quick(
                "檢查本月還能推進哪個目標",
                .growth,
                20,
                "本月還剩 \(daysLeft) 天，適合選一個月內能推進的下一步。",
                "本月視角",
                ["看一眼進行中目標", "選一個本月能完成的階段", "排出本週第一個 30 分鐘"]
            ),
            quick(
                "做一次本月健康檢查",
                .health,
                20,
                "月視角適合回看身體狀態，先做輕量盤點即可。",
                "本月視角",
                ["回想最近睡眠和運動", "寫下一個要改善的小習慣", "今天先做 20 分鐘"]
            )
        ]

        return result.filter { !existingTitles.contains(normalized($0.title)) }
    }

    private static func activeTaskRecommendations(context: TimeRecommendationContext) -> [TimeRecommendation] {
        let hour = Calendar.current.component(.hour, from: context.now)
        return TaskRecommender.secondary(
            from: context.tasks.filter { isSameDayFriendly($0, hour: hour) },
            primaryId: nil,
            maxCount: 2
        ).map { task in
            TimeRecommendation(
                id: "task-\(task.id.uuidString)",
                title: task.title,
                subtitle: "你的今日待辦裡，這件事現在可以推進。",
                reason: reasonForCurrentSlot(hour: hour),
                category: task.category,
                sourceLabel: "今日待辦",
                estimatedMinutes: task.estimatedMinutes,
                sopSteps: [
                    "先準備需要的物品或打開相關資料",
                    "設定 \(task.estimatedLabel.isEmpty ? "25 分鐘" : task.estimatedLabel) 的專注時間",
                    "做完後在今天頁標記完成"
                ],
                action: .none
            )
        }
    }

    private static func timeSlotRecommendations(
        context: TimeRecommendationContext,
        existingTitles: Set<String>
    ) -> [TimeRecommendation] {
        let hour = Calendar.current.component(.hour, from: context.now)
        let weekday = Calendar.current.component(.weekday, from: context.now)
        let isWeekend = weekday == 1 || weekday == 7
        let candidates: [TimeRecommendation]

        switch hour {
        case 6..<9:
            candidates = [
                quick("規劃今天最重要的一件事", .growth, 10, "早上適合先決定今天真正值得完成的事。", "早晨 SOP", ["寫下今天最重要的一件事", "確認它需要多久", "把第一步安排到今天"]),
                quick("出門散步 15 分鐘", .health, 15, "早晨的身體活動能讓今天更容易開始。", "早晨 SOP", ["換上方便走路的鞋", "走一段不需要交通安排的路線", "回來喝水並開始今天"])
            ]
        case 9..<12:
            candidates = [
                quick("推進一個重要目標 30 分鐘", .growth, 30, "上午更適合高專注工作，不適合塞入陪伴或大型計劃。", "高專注 SOP", ["選一個進行中的目標", "只做下一個未完成步驟", "30 分鐘後記錄進度"]),
                quick("閱讀或學習 20 分鐘", .growth, 20, "這段時間適合吸收和輸出，先做小段即可。", "高專注 SOP", ["打開一本書或課程", "只完成一小節", "記下一句有用的內容"])
            ]
        case 12..<14:
            candidates = [
                quick("好好吃一頓午餐", .health, 45, "中午應該先恢復能量，而不是開啟長任務。", "午間 SOP", ["離開工作畫面", "專心吃飯", "飯後留 5 分鐘休息"]),
                quick("傳訊息問候父母", .family, 5, "午休時間適合做低壓力的連結。", "午間 SOP", ["傳一句近況問候", "問他們今天過得如何", "如果方便再約下一次通話"])
            ]
        case 14..<18:
            candidates = [
                quick("完成一件生活小事", .creation, 30, "下午適合執行，不適合只停留在想法。", "下午 SOP", ["選一件能在半小時內完成的小事", "先處理最小步驟", "完成後清掉現場或紀錄"]),
                quick("運動 20 分鐘", .health, 20, "下午的體力通常足夠做一段短運動。", "下午 SOP", ["選擇走路、伸展或居家運動", "設定 20 分鐘", "結束後補水"])
            ]
        case 18..<21:
            candidates = [
                quick("陪家人吃飯或散步", .family, 60, "晚上 6 點到 9 點應優先留給陪伴。", "Family Time", ["放下工作訊息", "一起吃飯或走一段路", "拍一張今天的照片"]),
                quick("陪孩子玩 20 分鐘", .family, 20, "這段時間適合孩子互動，不適合開啟重工作。", "Family Time", ["讓孩子選一件小遊戲", "全程不看手機", "結束前給一個擁抱或稱讚"])
            ]
        case 21..<23:
            candidates = [
                quick("寫一句今天的反思", .growth, 5, "21 點後適合收尾，不應推薦開始工作。", "夜間收尾", ["回想今天完成了什麼", "寫下一句感受", "決定明天第一步"]),
                quick("規劃明天第一件事", .growth, 10, "睡前只需要做輕量規劃。", "夜間收尾", ["選出明天最重要的一件事", "寫下第一步", "不要展開新工作"])
            ]
        case 23...24, 0..<6:
            candidates = [
                TimeRecommendation(
                    id: "rest-late-night",
                    title: "今天先休息",
                    subtitle: "今天已經很努力了。",
                    reason: "深夜不再推薦任務，恢復比多做一件事更重要。",
                    category: .health,
                    sourceLabel: "休息 SOP",
                    estimatedMinutes: nil,
                    sopSteps: ["放下手機", "整理明天要用的物品", "早點睡，明天再繼續"],
                    action: .none
                )
            ]
        default:
            candidates = []
        }

        let weekendOnly = isWeekend
            ? [quick("安排一次附近的小散步", .experience, 60, "週末適合不需要遠行的戶外體驗。", "週末 SOP", ["選一個附近地點", "確認來回時間", "今天只完成這段小出門"])]
            : [quick("聯絡一位老朋友", .relationship, 10, "工作日也可以用很小的時間維持重要關係。", "工作日 SOP", ["傳一則近況", "問對方最近如何", "不要求立刻約成見面"])]

        return (candidates + weekendOnly).filter { !existingTitles.contains(normalized($0.title)) }
    }

    private static func familyRecommendations(
        context: TimeRecommendationContext,
        existingTitles: Set<String>
    ) -> [TimeRecommendation] {
        var result: [TimeRecommendation] = []
        let active = context.familyMembers.filter { !$0.isArchived }
        let parents = active.filter { [.father, .mother, .parent, .grandparent].contains($0.relation) }
        let children = active.filter { $0.relation == .child }

        if let parent = parents.sorted(by: { $0.currentAge > $1.currentAge }).first {
            let title = parent.currentAge >= 70 ? "問\(parent.name)一個年輕時的故事" : "和\(parent.name)聊 10 分鐘"
            result.append(quick(
                title,
                .family,
                10,
                "\(parent.name)今年 \(parent.currentAge) 歲，陪伴可以從一個很小的問題開始。",
                "父母年齡",
                parent.currentAge >= 70
                    ? ["問一個年輕時的故事", "讓他慢慢說完", "記下一句你想保存的話"]
                    : ["傳訊息問現在方不方便", "聊一件最近的小事", "約下一次吃飯或散步"]
            ))
        }

        if let child = children.sorted(by: { $0.currentAge < $1.currentAge }).first {
            result.append(childRecommendation(child))
        }

        return result.filter { !existingTitles.contains(normalized($0.title)) }
    }

    private static func ageRecommendations(
        context: TimeRecommendationContext,
        existingTitles: Set<String>
    ) -> [TimeRecommendation] {
        let age = context.metrics.ageYears
        let recommendation: TimeRecommendation

        switch age {
        case 0..<30:
            recommendation = quick("學一個小技能 20 分鐘", .growth, 20, "很多人在這個階段會累積長期能力，今天先做一小段。", "你的年齡", ["選一個正在學的技能", "只完成一個小單元", "記下下一次要接哪裡"])
        case 30..<40:
            recommendation = quick("建立一個健康小習慣", .health, 15, "很多人在 30 多歲開始重視長期體力和節奏。", "你的年齡", ["選一件今天能做的健康行動", "做到 15 分鐘即可", "明天重複同一件事"])
        case 40..<60:
            recommendation = quick("留下一個家庭回憶", .family, 15, "很多人在這個階段會更重視家人和可保存的回憶。", "你的年齡", ["找一張今天的照片", "寫一句當下的描述", "傳給一位家人"])
        default:
            recommendation = quick("記錄一段人生故事", .creation, 20, "很多人在這個階段會開始整理自己的故事。", "你的年齡", ["選一個人生片段", "用語音或文字記 20 分鐘", "留下時間和地點"])
        }

        return existingTitles.contains(normalized(recommendation.title)) ? [] : [recommendation]
    }

    private static func goalNextStepRecommendations(
        context: TimeRecommendationContext,
        existingTitles: Set<String>,
        limit: Int
    ) -> [TimeRecommendation] {
        context.goals
            .filter { $0.status == .active }
            .compactMap { goal -> TimeRecommendation? in
                let step = nextSmallStep(for: goal)
                guard !existingTitles.contains(normalized(step.title)) else { return nil }
                return TimeRecommendation(
                    id: "goal-step-\(goal.id.uuidString)",
                    title: step.title,
                    subtitle: "不是今天完成「\(goal.displayTitle)」，只是做下一步。",
                    reason: "長時間計劃不進入當天推薦，只保留今天能做的小行動。",
                    category: goal.category,
                    sourceLabel: "目標下一步",
                    estimatedMinutes: step.minutes,
                    sopSteps: step.steps,
                    action: .openGoal(goal.id)
                )
            }
            .prefix(limit)
            .map { $0 }
    }

    private static func childRecommendation(_ child: FamilyMember) -> TimeRecommendation {
        switch child.currentAge {
        case 0...5:
            return quick("陪\(child.name)讀一本故事書", .family, 15, "\(child.name)現在 \(child.currentAge) 歲，短時間、高陪伴感最合適。", "孩子年齡", ["讓孩子選一本書", "慢慢讀完", "拍下今天的小瞬間"])
        case 6...12:
            return quick("和\(child.name)一起做一道小料理", .family, 45, "\(child.name)現在 \(child.currentAge) 歲，適合一起動手完成一件小事。", "孩子年齡", ["選一道簡單料理", "讓孩子負責一個步驟", "一起吃掉或拍照記錄"])
        case 13...18:
            return quick("和\(child.name)散步聊天", .family, 30, "\(child.name)現在 \(child.currentAge) 歲，比起安排活動，更需要自然對話。", "孩子年齡", ["邀請一起走一段路", "問一個開放問題", "多聽，少急著給建議"])
        default:
            return quick("約\(child.name)吃一頓飯", .family, 60, "成年後的陪伴更需要主動安排，但今天可以先約起來。", "孩子年齡", ["傳訊息問最近哪天方便", "選一個輕鬆地點", "先把時間約下來"])
        }
    }

    private static func nextSmallStep(for goal: LifeGoal) -> (title: String, minutes: Int, steps: [String]) {
        if let stage = goal.stages.first(where: { !$0.isDone }) {
            return (
                "為「\(goal.title)」做一步：\(stage.title)",
                30,
                ["只處理「\(stage.title)」這一步", "設定 30 分鐘", "完成後回到目標頁更新進度"]
            )
        }

        return (
            "為「\(goal.title)」整理下一步",
            15,
            ["打開這個目標", "寫下下一個可執行動作", "不要今天展開整個計劃"]
        )
    }

    private static func quick(
        _ title: String,
        _ category: GoalCategory,
        _ minutes: Int,
        _ reason: String,
        _ source: String,
        _ steps: [String]
    ) -> TimeRecommendation {
        TimeRecommendation(
            id: "quick-\(normalized(title))",
            title: title,
            subtitle: "約 \(minutes) 分鐘，今天可以完成。",
            reason: reason,
            category: category,
            sourceLabel: source,
            estimatedMinutes: minutes,
            sopSteps: steps,
            action: .addTask(title: title, category: category, minutes: minutes)
        )
    }

    private static func isSameDayFriendly(_ task: LifeTask, hour: Int) -> Bool {
        guard task.isCurrentlyActive else { return false }
        if hour >= 23 || hour < 6 { return false }
        guard let minutes = task.estimatedMinutes else { return true }
        return minutes <= 240
    }

    private static func reasonForCurrentSlot(hour: Int) -> String {
        switch hour {
        case 6..<9: return "現在是開始一天的時段，適合做低阻力的第一步。"
        case 9..<12: return "現在是高專注時段，適合推進需要思考的任務。"
        case 12..<14: return "現在是休息時段，適合輕量行動。"
        case 14..<18: return "現在是執行時段，適合完成一件具體小事。"
        case 18..<21: return "現在是陪伴時段，適合把時間留給重要的人。"
        case 21..<23: return "現在是收尾時段，適合反思和輕量整理。"
        default: return "現在更適合休息，不建議開啟新任務。"
        }
    }

    private static func dedupe(_ items: [TimeRecommendation]) -> [TimeRecommendation] {
        var seen = Set<String>()
        return items.filter { item in
            let key = normalized(item.title)
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

import Foundation

struct GoalCatalogEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let category: GoalCategory
    let stageTitles: [String]?
    let estimatedHours: Int // 修改内容 — 預估任務總長（小時）

    func makeGoal() -> LifeGoal {
        let titles = stageTitles ?? GoalStageGenerator.titles(catalogId: id, title: title, category: category)
        return LifeGoal(
            title: title,
            category: category,
            stages: titles.map { GoalStage(title: $0) },
            catalogId: id,
            estimatedHours: estimatedHours // 修改内容 — 預帶預估值
        )
    }
}

enum GoalCatalog {
    static let all: [GoalCatalogEntry] = family + experience + growth + health + creation + relationship + dream + contribution

    static func entry(id: String) -> GoalCatalogEntry? {
        all.first { $0.id == id }
    }

    static func entries(for category: GoalCategory) -> [GoalCatalogEntry] {
        all.filter { $0.category == category }
    }

    // MARK: - 100 個可完成的人生事件（hours = 預估任務總長）修改内容

    private static let family: [GoalCatalogEntry] = [
        entry("f01", "帶父母旅行一次", .family, hours: 24),
        entry("f02", "拍一張全家福", .family, hours: 3),
        entry("f03", "陪孩子露營", .family, hours: 24),
        entry("f04", "為父母做一頓飯", .family, hours: 3),
        entry("f05", "陪父母看一場電影", .family, hours: 3),
        entry("f06", "帶孩子去博物館", .family, hours: 4),
        entry("f07", "寫一封給家人的信", .family, hours: 2),
        entry("f08", "整理一本家庭相簿", .family, hours: 8),
        entry("f09", "陪父母散步聊天", .family, hours: 2),
        entry("f10", "教父母使用一項新科技", .family, hours: 3),
        entry("f11", "為家人策劃一次驚喜", .family, hours: 6),
        entry("f12", "與兄弟姐妹深度談心", .family, hours: 2),
        entry("f13", "記錄一段家庭故事", .family, hours: 6),
    ]

    private static let experience: [GoalCatalogEntry] = [
        entry("e01", "看一次極光", .experience, stages: ["研究地點", "訂票安排", "出發", "親眼見到極光"], hours: 40),
        entry("e02", "搭一次熱氣球", .experience, hours: 6),
        entry("e03", "去一次北海道旅行", .experience, hours: 40),
        entry("e04", "在海邊看一次日出", .experience, hours: 4),
        entry("e05", "走一趟朝聖之路", .experience, hours: 200),
        entry("e06", "住一晚特色民宿", .experience, hours: 12),
        entry("e07", "品嚐米其林餐廳", .experience, hours: 4),
        entry("e08", "坐一次過夜火車", .experience, hours: 15),
        entry("e09", "去一個從未去過的城市", .experience, hours: 24),
        entry("e10", "參加一場現場音樂會", .experience, hours: 5),
        entry("e11", "在星空下露營一晚", .experience, hours: 15),
        entry("e12", "學做一道異國料理", .experience, hours: 6),
        entry("e13", "完成一次單人小旅行", .experience, hours: 16),
    ]

    private static let growth: [GoalCatalogEntry] = [
        entry("g01", "讀一本書", .growth, stages: ["選一本書", "開始閱讀", "閱讀完成"], hours: 8),
        entry("g02", "學會游泳", .growth, hours: 25),
        entry("g03", "學會基礎英文會話", .growth, hours: 50),
        entry("g04", "完成一門線上課程", .growth, hours: 20),
        entry("g05", "學會騎腳踏車", .growth, hours: 10),
        entry("g06", "學會一道拿手菜", .growth, hours: 8),
        entry("g07", "每天冥想兩週", .growth, hours: 4),
        entry("g08", "學會彈一首曲子", .growth, hours: 20),
        entry("g09", "寫完一本讀書筆記", .growth, hours: 10),
        entry("g10", "學會基礎攝影", .growth, hours: 15),
        entry("g11", "參加一次工作坊", .growth, hours: 6),
        entry("g12", "學會理財基礎知識", .growth, hours: 15),
        entry("g13", "培養一個晨間習慣", .growth, hours: 15),
    ]

    private static let health: [GoalCatalogEntry] = [
        entry("h01", "完成一次健檢", .health, hours: 3),
        entry("h02", "減重 5 公斤", .health, hours: 60),
        entry("h03", "學會慢跑", .health, hours: 20),
        entry("h04", "連續運動 30 天", .health, hours: 20),
        entry("h05", "戒糖一個月", .health, hours: 10),
        entry("h06", "每天走路一萬步兩週", .health, hours: 15),
        entry("h07", "嘗試瑜伽課程", .health, hours: 10),
        entry("h08", "改善睡眠品質", .health, hours: 15),
        entry("h09", "學會正確伸展", .health, hours: 8),
        entry("h10", "完成一次馬拉松或路跑", .health, hours: 60),
        entry("h11", "建立健康飲食習慣", .health, hours: 20),
        entry("h12", "戒除一個壞習慣", .health, hours: 20),
    ]

    private static let creation: [GoalCatalogEntry] = [
        entry("c01", "寫一篇文章", .creation, hours: 4),
        entry("c02", "完成一個 App", .creation, stages: ["有想法", "開始製作", "持續打磨", "上線"], hours: 120),
        entry("c03", "畫一幅畫", .creation, hours: 10),
        entry("c04", "錄製一支影片", .creation, hours: 12),
        entry("c05", "寫一首詩或歌詞", .creation, hours: 4),
        entry("c06", "完成一個手工作品", .creation, hours: 10),
        entry("c07", "拍一部短片", .creation, hours: 30),
        entry("c08", "設計一張海報", .creation, hours: 6),
        entry("c09", "寫一篇部落格", .creation, hours: 5),
        entry("c10", "完成一首原創曲", .creation, hours: 30),
        entry("c11", "做一個個人作品集", .creation, hours: 25),
        entry("c12", "完成一個攝影專題", .creation, hours: 30),
    ]

    private static let relationship: [GoalCatalogEntry] = [
        entry("r01", "見一位老朋友", .relationship, hours: 3),
        entry("r02", "修復一段關係", .relationship, hours: 10),
        entry("r03", "認識一位新朋友", .relationship, hours: 5),
        entry("r04", "向重要的人說謝謝", .relationship, hours: 1),
        entry("r05", "安排一次深度對話", .relationship, hours: 3),
        entry("r06", "為朋友準備一份禮物", .relationship, hours: 4),
        entry("r07", "參加一次聚會", .relationship, hours: 4),
        entry("r08", "寫一張感謝卡片", .relationship, hours: 1),
        entry("r09", "主動聯絡久未見的人", .relationship, hours: 1),
        entry("r10", "為伴侶策劃約會", .relationship, hours: 5),
        entry("r11", "成為某人的傾聽者", .relationship, hours: 3),
        entry("r12", "化解一個誤會", .relationship, hours: 4),
    ]

    private static let dream: [GoalCatalogEntry] = [
        entry("d01", "開始創業", .dream, stages: ["有想法", "開始製作", "上線", "第一位用戶"], hours: 300),
        entry("d02", "出版一本書", .dream, hours: 250),
        entry("d03", "買一間屬於自己的房子", .dream, hours: 100),
        entry("d04", "存到第一桶金", .dream, hours: 100),
        entry("d05", "轉換職涯跑道", .dream, hours: 80),
        entry("d06", "實現一個童年夢想", .dream, hours: 40),
        entry("d07", "去嚮往的國家生活一個月", .dream, hours: 160),
        entry("d08", "成立一個個人品牌", .dream, hours: 100),
        entry("d09", "完成一個長期計畫", .dream, hours: 100),
        entry("d10", "實現財務自由的第一步", .dream, hours: 40),
        entry("d11", "站上公開演講的舞台", .dream, hours: 20),
        entry("d12", "把想法變成產品", .dream, hours: 150),
    ]

    private static let contribution: [GoalCatalogEntry] = [
        entry("b01", "做一次志工", .contribution, hours: 8),
        entry("b02", "幫助一個陌生人", .contribution, hours: 2),
        entry("b03", "捐贈一本書", .contribution, hours: 1),
        entry("b04", "參與社區服務", .contribution, hours: 6),
        entry("b05", "為公益項目捐款", .contribution, hours: 1),
        entry("b06", "分享知識給需要的人", .contribution, hours: 4),
        entry("b07", "清理一次公共空間", .contribution, hours: 3),
        entry("b08", "為環保做一件小事", .contribution, hours: 2),
        entry("b09", "指導一位後輩", .contribution, hours: 10),
        entry("b10", "參與一次募款活動", .contribution, hours: 8),
        entry("b11", "把多餘物品送給需要的人", .contribution, hours: 2),
        entry("b12", "為鄰居做一件好事", .contribution, hours: 2),
        entry("b13", "記錄並分享一段善意", .contribution, hours: 2),
    ]

    private static func entry(
        _ id: String,
        _ title: String,
        _ category: GoalCategory,
        stages: [String]? = nil,
        hours: Int // 修改内容
    ) -> GoalCatalogEntry {
        GoalCatalogEntry(id: id, title: title, category: category, stageTitles: stages, estimatedHours: hours)
    }
}

import Foundation

struct GoalCatalogEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let category: GoalCategory
    let stageTitles: [String]?

    func makeGoal() -> LifeGoal {
        let stages = (stageTitles ?? category.defaultStageTitles).map { GoalStage(title: $0) }
        return LifeGoal(
            title: title,
            category: category,
            stages: stages,
            catalogId: id
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

    // MARK: - 100 個可完成的人生事件

    private static let family: [GoalCatalogEntry] = [
        entry("f01", "帶父母旅行一次", .family),
        entry("f02", "拍一張全家福", .family),
        entry("f03", "陪孩子露營", .family),
        entry("f04", "為父母做一頓飯", .family),
        entry("f05", "陪父母看一場電影", .family),
        entry("f06", "帶孩子去博物館", .family),
        entry("f07", "寫一封給家人的信", .family),
        entry("f08", "整理一本家庭相簿", .family),
        entry("f09", "陪父母散步聊天", .family),
        entry("f10", "教父母使用一項新科技", .family),
        entry("f11", "為家人策劃一次驚喜", .family),
        entry("f12", "與兄弟姐妹深度談心", .family),
        entry("f13", "記錄一段家庭故事", .family),
    ]

    private static let experience: [GoalCatalogEntry] = [
        entry("e01", "看一次極光", .experience, stages: ["研究地點", "訂票安排", "出發", "親眼見到極光"]),
        entry("e02", "搭一次熱氣球", .experience),
        entry("e03", "去一次北海道旅行", .experience),
        entry("e04", "在海邊看一次日出", .experience),
        entry("e05", "走一趟朝聖之路", .experience),
        entry("e06", "住一晚特色民宿", .experience),
        entry("e07", "品嚐米其林餐廳", .experience),
        entry("e08", "坐一次過夜火車", .experience),
        entry("e09", "去一個從未去過的城市", .experience),
        entry("e10", "參加一場現場音樂會", .experience),
        entry("e11", "在星空下露營一晚", .experience),
        entry("e12", "學做一道異國料理", .experience),
        entry("e13", "完成一次單人小旅行", .experience),
    ]

    private static let growth: [GoalCatalogEntry] = [
        entry("g01", "讀一本書", .growth, stages: ["選一本書", "開始閱讀", "閱讀完成"]),
        entry("g02", "學會游泳", .growth),
        entry("g03", "學會基礎英文會話", .growth),
        entry("g04", "完成一門線上課程", .growth),
        entry("g05", "學會騎腳踏車", .growth),
        entry("g06", "學會一道拿手菜", .growth),
        entry("g07", "每天冥想兩週", .growth),
        entry("g08", "學會彈一首曲子", .growth),
        entry("g09", "寫完一本讀書筆記", .growth),
        entry("g10", "學會基礎攝影", .growth),
        entry("g11", "參加一次工作坊", .growth),
        entry("g12", "學會理財基礎知識", .growth),
        entry("g13", "培養一個晨間習慣", .growth),
    ]

    private static let health: [GoalCatalogEntry] = [
        entry("h01", "完成一次健檢", .health),
        entry("h02", "減重 5 公斤", .health),
        entry("h03", "學會慢跑", .health),
        entry("h04", "連續運動 30 天", .health),
        entry("h05", "戒糖一個月", .health),
        entry("h06", "每天走路一萬步兩週", .health),
        entry("h07", "嘗試瑜伽課程", .health),
        entry("h08", "改善睡眠品質", .health),
        entry("h09", "學會正確伸展", .health),
        entry("h10", "完成一次馬拉松或路跑", .health),
        entry("h11", "建立健康飲食習慣", .health),
        entry("h12", "戒除一個壞習慣", .health),
    ]

    private static let creation: [GoalCatalogEntry] = [
        entry("c01", "寫一篇文章", .creation),
        entry("c02", "完成一個 App", .creation, stages: ["有想法", "開始製作", "持續打磨", "上線"]),
        entry("c03", "畫一幅畫", .creation),
        entry("c04", "錄製一支影片", .creation),
        entry("c05", "寫一首詩或歌詞", .creation),
        entry("c06", "完成一個手工作品", .creation),
        entry("c07", "拍一部短片", .creation),
        entry("c08", "設計一張海報", .creation),
        entry("c09", "寫一篇部落格", .creation),
        entry("c10", "完成一首原創曲", .creation),
        entry("c11", "做一個個人作品集", .creation),
        entry("c12", "完成一個攝影專題", .creation),
    ]

    private static let relationship: [GoalCatalogEntry] = [
        entry("r01", "見一位老朋友", .relationship),
        entry("r02", "修復一段關係", .relationship),
        entry("r03", "認識一位新朋友", .relationship),
        entry("r04", "向重要的人說謝謝", .relationship),
        entry("r05", "安排一次深度對話", .relationship),
        entry("r06", "為朋友準備一份禮物", .relationship),
        entry("r07", "參加一次聚會", .relationship),
        entry("r08", "寫一張感謝卡片", .relationship),
        entry("r09", "主動聯絡久未見的人", .relationship),
        entry("r10", "為伴侶策劃約會", .relationship),
        entry("r11", "成為某人的傾聽者", .relationship),
        entry("r12", "化解一個誤會", .relationship),
    ]

    private static let dream: [GoalCatalogEntry] = [
        entry("d01", "開始創業", .dream, stages: ["有想法", "開始製作", "上線", "第一位用戶"]),
        entry("d02", "出版一本書", .dream),
        entry("d03", "買一間屬於自己的房子", .dream),
        entry("d04", "存到第一桶金", .dream),
        entry("d05", "轉換職涯跑道", .dream),
        entry("d06", "實現一個童年夢想", .dream),
        entry("d07", "去嚮往的國家生活一個月", .dream),
        entry("d08", "成立一個個人品牌", .dream),
        entry("d09", "完成一個長期計畫", .dream),
        entry("d10", "實現財務自由的第一步", .dream),
        entry("d11", "站上公開演講的舞台", .dream),
        entry("d12", "把想法變成產品", .dream),
    ]

    private static let contribution: [GoalCatalogEntry] = [
        entry("b01", "做一次志工", .contribution),
        entry("b02", "幫助一個陌生人", .contribution),
        entry("b03", "捐贈一本書", .contribution),
        entry("b04", "參與社區服務", .contribution),
        entry("b05", "為公益項目捐款", .contribution),
        entry("b06", "分享知識給需要的人", .contribution),
        entry("b07", "清理一次公共空間", .contribution),
        entry("b08", "為環保做一件小事", .contribution),
        entry("b09", "指導一位後輩", .contribution),
        entry("b10", "參與一次募款活動", .contribution),
        entry("b11", "把多餘物品送給需要的人", .contribution),
        entry("b12", "為鄰居做一件好事", .contribution),
        entry("b13", "記錄並分享一段善意", .contribution),
    ]

    private static func entry(
        _ id: String,
        _ title: String,
        _ category: GoalCategory,
        stages: [String]? = nil
    ) -> GoalCatalogEntry {
        GoalCatalogEntry(id: id, title: title, category: category, stageTitles: stages)
    }
}

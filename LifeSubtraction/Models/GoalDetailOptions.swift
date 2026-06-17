import Foundation

// MARK: - Selection

struct GoalDetailSelection: Codable, Hashable, Identifiable {
    var fieldId: String
    var label: String
    var selectedValue: String

    var id: String { fieldId }
}

// MARK: - Spec

struct GoalDetailFieldSpec: Hashable {
    let id: String
    let label: String
    let placeholder: String
    let options: [String]
    let allowsCustom: Bool
    /// 依父欄位選項提供子選項，例如菜系 → 菜色
    let dependentOptions: [String: [String]]?
    let dependsOnFieldId: String?

    init(
        id: String,
        label: String,
        placeholder: String = "自訂…",
        options: [String] = [],
        allowsCustom: Bool = true,
        dependsOnFieldId: String? = nil,
        dependentOptions: [String: [String]]? = nil
    ) {
        self.id = id
        self.label = label
        self.placeholder = placeholder
        self.options = options
        self.allowsCustom = allowsCustom
        self.dependsOnFieldId = dependsOnFieldId
        self.dependentOptions = dependentOptions
    }
}

struct GoalDetailSpec: Hashable {
    let catalogId: String
    let fields: [GoalDetailFieldSpec]
}

// MARK: - Option item

struct GoalDetailOptionItem: Identifiable, Hashable {
    let value: String
    let isBuiltin: Bool
    let isShared: Bool
    let isLocal: Bool

    var id: String { value }
}

// MARK: - Registry

enum GoalDetailOptions {
    private static let genericField = GoalDetailFieldSpec(
        id: "detail",
        label: "具體內容",
        placeholder: "描述你想完成的細節…",
        options: [],
        allowsCustom: true
    )

    static func spec(for catalogId: String?) -> GoalDetailSpec? {
        guard let catalogId else { return nil }
        return specs[catalogId]
    }

    static func fields(for catalogId: String?) -> [GoalDetailFieldSpec] {
        guard let catalogId else { return [genericField] }
        return specs[catalogId]?.fields ?? [genericField]
    }

    static func defaultSelections(for catalogId: String?) -> [GoalDetailSelection] {
        fields(for: catalogId).map {
            GoalDetailSelection(fieldId: $0.id, label: $0.label, selectedValue: "")
        }
    }

    static func allOptions(
        for field: GoalDetailFieldSpec,
        catalogId: String?,
        selections: [GoalDetailSelection]
    ) -> [GoalDetailOptionItem] {
        var seen = Set<String>()
        var items: [GoalDetailOptionItem] = []

        func append(_ value: String, builtin: Bool = false, shared: Bool = false, local: Bool = false) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { return }
            seen.insert(trimmed)
            items.append(GoalDetailOptionItem(
                value: trimmed,
                isBuiltin: builtin,
                isShared: shared,
                isLocal: local
            ))
        }

        var builtin = field.options
        if let parentId = field.dependsOnFieldId,
           let parentValue = selections.first(where: { $0.fieldId == parentId })?.selectedValue,
           !parentValue.isEmpty,
           let dependent = field.dependentOptions?[parentValue] {
            builtin = dependent + builtin
        }
        builtin.forEach { append($0, builtin: true) }

        let storeId = catalogId ?? "__generic__"
        (sharedPresets[storeId]?[field.id] ?? []).forEach { append($0, shared: true) }
        (localPresets[storeId]?[field.id] ?? []).forEach { append($0, local: true) }

        return items
    }

    static func resolvedOptions(
        for field: GoalDetailFieldSpec,
        catalogId: String?,
        selections: [GoalDetailSelection]
    ) -> [String] {
        allOptions(for: field, catalogId: catalogId, selections: selections).map(\.value)
    }

    // MARK: Preset stores

    private static var localPresets: [String: [String: [String]]] {
        get {
            LocalJSONStore.load(
                [String: [String: [String]]].self,
                key: StorageKey.goalDetailCustomOptions,
                defaultValue: [:]
            )
        }
        set {
            LocalJSONStore.save(newValue, key: StorageKey.goalDetailCustomOptions)
        }
    }

    private static var sharedPresets: [String: [String: [String]]] {
        get {
            LocalJSONStore.load(
                [String: [String: [String]]].self,
                key: StorageKey.goalDetailSharedPresets,
                defaultValue: [:]
            )
        }
        set {
            LocalJSONStore.save(newValue, key: StorageKey.goalDetailSharedPresets)
        }
    }

    static func addLocalPreset(catalogId: String, fieldId: String, option: String) {
        var store = localPresets
        appendOption(&store, catalogId: catalogId, fieldId: fieldId, option: option)
        localPresets = store
    }

    static func addSharedPreset(catalogId: String, fieldId: String, option: String) {
        var shared = sharedPresets
        appendOption(&shared, catalogId: catalogId, fieldId: fieldId, option: option)
        sharedPresets = shared

        var local = localPresets
        appendOption(&local, catalogId: catalogId, fieldId: fieldId, option: option)
        localPresets = local
    }

    private static func appendOption(
        _ store: inout [String: [String: [String]]],
        catalogId: String,
        fieldId: String,
        option: String
    ) {
        let trimmed = option.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var fields = store[catalogId] ?? [:]
        var options = fields[fieldId] ?? []
        guard !options.contains(trimmed) else { return }
        options.append(trimmed)
        fields[fieldId] = options
        store[catalogId] = fields
    }

    // MARK: Partial catalog specs（逐步擴充）

    private static let specs: [String: GoalDetailSpec] = [
        "g06": GoalDetailSpec(catalogId: "g06", fields: [
            GoalDetailFieldSpec(
                id: "cuisine",
                label: "菜系",
                options: ["中式", "台式", "日式", "韓式", "泰式", "義式", "法式", "川菜", "粵菜"]
            ),
            GoalDetailFieldSpec(
                id: "dish",
                label: "菜色",
                placeholder: "輸入菜名…",
                dependsOnFieldId: "cuisine",
                dependentOptions: [
                    "中式": ["紅燒肉", "糖醋排骨", "宮保雞丁", "麻婆豆腐", "番茄炒蛋"],
                    "台式": ["三杯雞", "滷肉飯", "蚵仔煎", "牛肉麵", "鹹酥雞"],
                    "日式": ["咖哩飯", "親子丼", "味噌湯", "壽司卷", "大阪燒"],
                    "韓式": ["泡菜鍋", "石鍋拌飯", "韓式炸雞", "部隊鍋"],
                    "泰式": ["打拋豬", "綠咖哩", "冬陰功", "芒果糯米飯"],
                    "義式": ["義大利麵", "燉飯", "瑪格麗特披薩", "提拉米蘇"],
                    "法式": ["法式吐司", "可麗露", "法式燉菜", "舒芙蕾"],
                    "川菜": ["水煮魚", "魚香茄子", "口水雞", "夫妻肺片"],
                    "粵菜": ["白切雞", "清蒸魚", "蝦餃", "煲仔飯"],
                ]
            ),
        ]),
        "g01": GoalDetailSpec(catalogId: "g01", fields: [
            GoalDetailFieldSpec(
                id: "genre",
                label: "類型",
                options: ["小說", "非虛構", "傳記", "歷史", "哲學", "科幻", "心理", "商業"]
            ),
            GoalDetailFieldSpec(
                id: "book",
                label: "書名",
                placeholder: "輸入或搜尋書名…",
                options: ["原子習慣", "被討厭的勇氣", "小王子", "百年孤獨"]
            ),
        ]),
        "f01": GoalDetailSpec(catalogId: "f01", fields: [
            GoalDetailFieldSpec(
                id: "region",
                label: "地區",
                options: ["台灣", "日本", "韓國", "東南亞", "歐洲", "北美", "澳洲"]
            ),
            GoalDetailFieldSpec(
                id: "destination",
                label: "目的地",
                placeholder: "輸入城市或景點…",
                dependsOnFieldId: "region",
                dependentOptions: [
                    "台灣": ["花蓮", "台東", "澎湖", "阿里山", "九份"],
                    "日本": ["京都", "大阪", "北海道", "沖繩", "東京"],
                    "韓國": ["首爾", "釜山", "濟州島"],
                    "東南亞": ["曼谷", "峇里島", "新加坡", "清邁"],
                    "歐洲": ["巴黎", "羅馬", "倫敦", "布拉格"],
                    "北美": ["紐約", "舊金山", "溫哥華"],
                    "澳洲": ["雪梨", "墨爾本"],
                ]
            ),
        ]),
        "g08": GoalDetailSpec(catalogId: "g08", fields: [
            GoalDetailFieldSpec(
                id: "instrument",
                label: "樂器",
                options: ["鋼琴", "吉他", "烏克麗麗", "小提琴", "直笛", "口琴"]
            ),
            GoalDetailFieldSpec(
                id: "piece",
                label: "曲目",
                placeholder: "輸入曲名…",
                dependsOnFieldId: "instrument",
                dependentOptions: [
                    "鋼琴": ["小星星", "卡農", "天空之城", "夢中的婚禮"],
                    "吉他": ["情書", "平凡之路", "Hotel California"],
                    "烏克麗麗": ["情書", "小手拉大手"],
                    "小提琴": ["小夜曲", "四季·春"],
                ]
            ),
        ]),
        "e03": GoalDetailSpec(catalogId: "e03", fields: [
            GoalDetailFieldSpec(
                id: "season",
                label: "季節",
                options: ["春季", "夏季", "秋季", "冬季"]
            ),
            GoalDetailFieldSpec(
                id: "highlight",
                label: "想做的事",
                options: ["賞櫻", "滑雪", "泡溫泉", "海鮮美食", "薰衣草", "雪祭"]
            ),
        ]),
        "h10": GoalDetailSpec(catalogId: "h10", fields: [
            GoalDetailFieldSpec(
                id: "distance",
                label: "距離",
                options: ["5K", "10K", "半馬", "全馬"]
            ),
            GoalDetailFieldSpec(
                id: "event",
                label: "賽事",
                placeholder: "輸入賽事名稱…",
                options: ["台北馬拉松", "新竹城市馬拉松", "墾丁路跑"]
            ),
        ]),
        "c01": GoalDetailSpec(catalogId: "c01", fields: [
            GoalDetailFieldSpec(
                id: "topic",
                label: "主題類型",
                options: ["生活", "旅行", "成長", "職涯", "情感", "評論"]
            ),
            GoalDetailFieldSpec(
                id: "articleTitle",
                label: "文章標題",
                placeholder: "輸入標題…",
                options: []
            ),
        ]),
        "g02": GoalDetailSpec(catalogId: "g02", fields: [
            GoalDetailFieldSpec(
                id: "style",
                label: "泳姿",
                options: ["自由式", "蛙式", "仰式", "蝶式"]
            ),
            GoalDetailFieldSpec(
                id: "venue",
                label: "練習地點",
                placeholder: "泳池或地點…",
                options: ["社區泳池", "健身房", "戶外泳池"]
            ),
        ]),
        "e01": GoalDetailSpec(catalogId: "e01", fields: [
            GoalDetailFieldSpec(
                id: "country",
                label: "國家",
                options: ["冰島", "挪威", "芬蘭", "瑞典", "加拿大", "阿拉斯加"]
            ),
            GoalDetailFieldSpec(
                id: "spot",
                label: "觀測點",
                placeholder: "輸入地點…",
                options: ["特羅姆瑟", "羅瓦涅米", "黃刀鎮"]
            ),
        ]),
        "r10": GoalDetailSpec(catalogId: "r10", fields: [
            GoalDetailFieldSpec(
                id: "occasion",
                label: "場合",
                options: ["紀念日", "生日", "日常約會", "道歉和好", "驚喜"]
            ),
            GoalDetailFieldSpec(
                id: "plan",
                label: "約會內容",
                options: ["晚餐", "電影", "散步", "短途旅行", "手作體驗"]
            ),
        ]),
    ]
}

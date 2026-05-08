import Foundation

// 修改内容 — 輕量 JSON 持久化工具，Family System 用
enum LocalJSONStore {
    static func load<T: Decodable>(_ type: T.Type, key: String, defaultValue: T) -> T {
        guard let data = UserDefaults.shared.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data)
        else { return defaultValue }
        return decoded
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let encoded = try? JSONEncoder().encode(value) else { return }
        UserDefaults.shared.set(encoded, forKey: key)
    }
}

import Foundation
import Combine

/// 家人資料集中管理。
final class FamilyStore: ObservableObject {
    @Published var members: [FamilyMember] = []

    init() {
        load()
    }

    var activeMembers: [FamilyMember] {
        members.filter { !$0.isArchived }
    }

    /// 父母/長輩類關係的最短剩餘年數；無資料時回傳 nil。
    var parentYearsRemaining: Int? {
        let parentRelations: Set<FamilyRelation> = [.father, .mother, .parent, .grandparent]
        let years = activeMembers
            .filter { parentRelations.contains($0.relation) }
            .map(\.yearsRemaining)
        guard !years.isEmpty else { return nil }
        return years.min()
    }

    func load() {
        members = LocalJSONStore.load(
            [FamilyMember].self,
            key: StorageKey.familyMembers,
            defaultValue: []
        )
    }

    func save() {
        LocalJSONStore.save(members, key: StorageKey.familyMembers)
    }

    func add(_ member: FamilyMember) {
        members.append(member)
        save()
    }

    func update(_ member: FamilyMember) {
        guard let index = members.firstIndex(where: { $0.id == member.id }) else { return }
        members[index] = member
        save()
    }
}

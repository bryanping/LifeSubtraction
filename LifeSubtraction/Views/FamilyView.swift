import SwiftUI

// 修改内容 — 家人管理 Sheet（從設定頁進入，不再是 Tab）
struct FamilyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager

    @State private var members: [FamilyMember] = []
    @State private var showingAddMember = false
    @State private var showingPaywall = false

    var activeMembers: [FamilyMember] { members.filter { !$0.isArchived } }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    introCard
                        .padding(.horizontal)

                    memberListSection
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
                .padding(.vertical, 8)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("管理家人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { handleAddMember() } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(LifeTheme.accent)
                    }
                }
            }
            .onAppear { loadMembers() }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView { member in
                    members.append(member)
                    saveMembers()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                FamilyPaywallView().environmentObject(storeManager)
            }
        }
    }

    // 修改内容 — 說明卡
    var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(LifeTheme.accent)
                Text("重要的人")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
            }
            Text("在「你還有幾次？」新增項目時，可關聯這裡的家人，計算你們共同剩下的時間。")
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)

            if !storeManager.isPremium {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.warm)
                    Text("免費版最多 1 位。升級後無限制。")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
                .padding(.top, 2)
            }
        }
        .cardStyle()
    }

    // 修改内容 — 家人列表
    var memberListSection: some View {
        VStack(spacing: 0) {
            if activeMembers.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activeMembers.enumerated()), id: \.element.id) { index, member in
                        memberRow(member)
                        if index < activeMembers.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 0.5)
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LifeTheme.glassFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                )
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.largeTitle)
                .foregroundStyle(LifeTheme.accent)
            Text("還沒有家人資料")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("新增後，可在「你還有幾次？」項目中關聯。")
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton("新增家人", icon: "plus") {
                handleAddMember()
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }

    func memberRow(_ member: FamilyMember) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LifeTheme.accentSoft)
                    .frame(width: 38, height: 38)
                Image(systemName: member.relation.iconName)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text("\(member.relation.displayName) · \(member.currentAge) 歲 · 剩 \(member.yearsRemaining) 年")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            Spacer()

            Button {
                archiveMember(member)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    func handleAddMember() {
        if storeManager.canAddFamilyMember(currentCount: activeMembers.count) {
            showingAddMember = true
        } else {
            showingPaywall = true
        }
    }

    func archiveMember(_ member: FamilyMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index].isArchived = true
            saveMembers()
        }
    }

    func loadMembers() {
        members = LocalJSONStore.load(
            [FamilyMember].self,
            key: AppConstants.Key.familyMembers,
            defaultValue: []
        )
    }

    func saveMembers() {
        LocalJSONStore.save(members, key: AppConstants.Key.familyMembers)
    }
}

import SwiftUI

// 修改内容 — 家人系統主頁
struct FamilyView: View {
    @EnvironmentObject var storeManager: StoreManager

    @State private var members: [FamilyMember] = []
    @State private var showingAddMember = false
    @State private var showingPaywall = false

    var activeMembers: [FamilyMember] { members.filter { !$0.isArchived } }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                        .padding(.horizontal)
                    memberList
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("家人")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
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
                .environmentObject(storeManager)
            }
            .sheet(isPresented: $showingPaywall) {
                FamilyPaywallView()
                    .environmentObject(storeManager)
            }
        }
    }

    // 修改内容 — 說明卡
    var introCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(LifeTheme.accent)
                Text("你們共同剩下的時間")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
            }
            Text("這不是你的剩餘時間，而是你和重要的人還能一起擁有的時間。")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .cardStyle()
    }

    // 修改内容 — 家人列表
    var memberList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("家人資料")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                if !storeManager.isPremium {
                    Text("免費 1 位")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                }
            }

            if activeMembers.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activeMembers.enumerated()), id: \.element.id) { index, member in
                        NavigationLink {
                            FamilyMemberDetailView(member: member)
                        } label: {
                            familyMemberRow(member)
                        }
                        .buttonStyle(.plain)

                        if index < activeMembers.count - 1 {
                            divider
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
            Text("新增第一位重要的人")
                .font(.headline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("開始計算你們還有多少次見面、通話、旅行與陪伴。")
                .font(.subheadline)
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

    func familyMemberRow(_ member: FamilyMember) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LifeTheme.accentSoft)
                    .frame(width: 40, height: 40)
                Image(systemName: member.relation.iconName)
                    .foregroundStyle(LifeTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text("\(member.relation.displayName) · \(member.currentAge) 歲")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.yearsRemaining)")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text("年")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }

    func handleAddMember() {
        if storeManager.canAddFamilyMember(currentCount: activeMembers.count) {
            showingAddMember = true
        } else {
            showingPaywall = true
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

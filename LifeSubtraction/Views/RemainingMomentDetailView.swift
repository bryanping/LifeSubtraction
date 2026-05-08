import SwiftUI

// 修改内容 — 「你還有幾次？」項目詳情頁
struct RemainingMomentDetailView: View {
    let item: RemainingMomentItem
    let userYearsRemaining: Int
    let familyMembers: [FamilyMember]

    private var linkedMember: FamilyMember? {
        guard let id = item.linkedFamilyMemberId else { return nil }
        return familyMembers.first { $0.id == id && !$0.isArchived }
    }

    private var count: Int {
        item.remainingCount(userYearsRemaining: userYearsRemaining, familyMembers: familyMembers)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                countCard
                    .padding(.horizontal)

                if let member = linkedMember {
                    memberContextCard(member: member)
                        .padding(.horizontal)
                }

                frequencyCard
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
            .padding(.vertical, 8)
        }
        .background(LifeTheme.subtleBackground.ignoresSafeArea())
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // 修改内容 — 大數字卡
    var countCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LifeTheme.accentSoft)
                    .frame(width: 72, height: 72)
                Image(systemName: item.icon)
                    .font(.system(size: 30))
                    .foregroundStyle(LifeTheme.accent)
            }

            VStack(spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(count)")
                        .font(.system(size: 72, weight: .light, design: .rounded))
                        .foregroundStyle(LifeTheme.accent)
                    Text("次")
                        .font(.title2)
                        .foregroundStyle(LifeTheme.textSecondary)
                }

                contextSentence
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }

    // 修改内容 — 核心文案，有家人時用「你和X」，否則用「你」
    var contextSentence: Text {
        if let member = linkedMember {
            return Text("你和") + Text(member.name).foregroundStyle(LifeTheme.accent) + Text(" 大約還有 \(count) 次\(item.name)的機會")
        } else {
            return Text("你大約還有 \(count) 次\(item.name)的機會")
        }
    }

    // 修改内容 — 家人資訊卡（有關聯時顯示）
    func memberContextCard(member: FamilyMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LifeTheme.accentSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: member.relation.iconName)
                        .foregroundStyle(LifeTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(LifeTheme.textPrimary)
                    Text("\(member.relation.displayName) · \(member.currentAge) 歲")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(member.yearsRemaining)")
                        .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                        .foregroundStyle(LifeTheme.textPrimary)
                    Text("年")
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textSecondary)
                }
            }

            Text("這不是你的倒數，而是你們還能一起共度的時間。")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .cardStyle()
    }

    // 修改内容 — 頻率說明卡
    var frequencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(LifeTheme.accent)
                Text("頻率設定")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
            }

            HStack {
                Text(item.frequency.displayName)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                Spacer()
                Text("≈ \(item.frequency.timesPerYear) 次/年")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            let years = linkedMember?.yearsRemaining ?? userYearsRemaining
            Text("基於 \(years) 年的共同時間估算。")
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .cardStyle()
    }
}

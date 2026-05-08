import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: LifeStore
    @EnvironmentObject var storeManager: StoreManager

    // 修改内容 — 動態「你還有幾次？」
    @State private var moments: [RemainingMomentItem] = []
    @State private var familyMembers: [FamilyMember] = []
    @State private var showingAddMoment = false

    var activeItems: [RemainingMomentItem] { moments.filter { !$0.isArchived } }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(label: "已活過天數", value: store.daysLived.formatted(), sub: "在你身後", icon: "arrow.left")
                        StatCard(label: "剩餘天數", value: store.daysRemaining.formatted(), sub: "在你前方", icon: "arrow.right", accent: true)
                        StatCard(label: "已用生命", value: "\(Int(store.percentUsed * 100))%", sub: "已完成", icon: "chart.pie.fill")
                        StatCard(label: "現在年齡", value: "\(store.ageYears)", sub: "歲", icon: "person.fill")
                    }
                    .padding(.horizontal)

                    progressBar
                        .padding(.horizontal)

                    countdownSection
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
                .padding(.vertical, 8)
            }
            .scrollContentBackground(.hidden)                  // // modified — 不蓋住底色
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("人生減法")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)   // // modified
            .onAppear { loadData() }
            .sheet(isPresented: $showingAddMoment, onDismiss: loadData) {
                AddRemainingMomentView { item in
                    moments.append(item)
                    saveMoments()
                }
                .environmentObject(storeManager)
            }
        }
    }

    // MARK: - Hero  // modified — 大號數字 + 內嵌進度條，去掉花俏紋理

    var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LifeTheme.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5) // // modified
                )

            VStack(spacing: 6) {
                Text("剩餘的時間")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.85))            // // modified
                Text(store.daysRemaining.formatted())
                    .font(.system(size: 76, weight: .light, design: .rounded))
                    .foregroundStyle(Color.white)                          // // modified
                    .padding(.top, -2)
                Text("天")
                    .font(.title3)
                    .foregroundStyle(Color.white.opacity(0.85))            // // modified
                    .padding(.top, -10)

                // 內嵌進度條  // modified
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("生命進度")
                            .font(.caption).foregroundStyle(Color.white.opacity(0.85))
                        Spacer()
                        Text("\(Int(store.percentUsed * 100))% / 100%")
                            .font(.caption).foregroundStyle(Color.white.opacity(0.85))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.25))      // // modified
                            Capsule().fill(Color.white)                    // // modified
                                .frame(width: geo.size.width * store.percentUsed)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.top, 14)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: LifeTheme.accent.opacity(0.20), radius: 20, y: 10) // // modified — 微 glow
    }

    // MARK: - 總體進度  // modified

    var progressBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .foregroundStyle(LifeTheme.accent)
                Text("總體進度")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified
                Spacer()
                Text("\(Int(store.percentUsed * 100))%")
                    .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                    .foregroundStyle(LifeTheme.accent)
            }
            ProgressBar(value: store.percentUsed)
            Text("已使用 \(Int(store.percentUsed * 100))%，剩餘 \(100 - Int(store.percentUsed * 100))%")
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)                  // // modified
        }
        .cardStyle()
    }

    // MARK: - 你還有幾次（動態）  // 修改内容

    var countdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("你還有幾次？")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Button {
                    showingAddMoment = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LifeTheme.accent)
                        .font(.title3)
                }
            }

            if activeItems.isEmpty {
                momentEmptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activeItems.enumerated()), id: \.element.id) { index, item in
                        let count = item.remainingCount(
                            userYearsRemaining: store.metrics.yearsRemaining,
                            familyMembers: familyMembers
                        )
                        let linkedMember = familyMembers.first {
                            $0.id == item.linkedFamilyMemberId && !$0.isArchived
                        }
                        NavigationLink {
                            RemainingMomentDetailView(
                                item: item,
                                userYearsRemaining: store.metrics.yearsRemaining,
                                familyMembers: familyMembers
                            )
                        } label: {
                            momentRow(item: item, count: count, linkedMember: linkedMember)
                        }
                        .buttonStyle(.plain)

                        if index < activeItems.count - 1 {
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

    // 修改内容 — 動態列
    func momentRow(item: RemainingMomentItem, count: Int, linkedMember: FamilyMember?) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LifeTheme.accentSoft)
                    .frame(width: 36, height: 36)
                Image(systemName: item.icon)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                if let member = linkedMember {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                        Text(member.name)
                    }
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.accent.opacity(0.7))
                } else {
                    Text(item.frequency.displayName)
                        .font(.caption2)
                        .foregroundStyle(LifeTheme.textTertiary)
                }
            }

            Spacer()

            Text("\(count.formatted())")
                .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("次")
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    var momentEmptyState: some View {
        Button {
            showingAddMoment = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(LifeTheme.accent)
                Text("新增第一個項目")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // 修改内容 — 載入 + 首次預設
    func loadData() {
        familyMembers = LocalJSONStore.load(
            [FamilyMember].self,
            key: AppConstants.Key.familyMembers,
            defaultValue: []
        )
        let saved = LocalJSONStore.load(
            [RemainingMomentItem].self,
            key: AppConstants.Key.remainingMoments,
            defaultValue: []
        )
        if saved.isEmpty {
            moments = RemainingMomentItem.defaults
            saveMoments()
        } else {
            moments = saved
        }
    }

    func saveMoments() {
        LocalJSONStore.save(moments, key: AppConstants.Key.remainingMoments)
    }
}

// MARK: - StatCard  // modified

struct StatCard: View {
    let label: String
    let value: String
    let sub: String
    var icon: String = "circle"
    var accent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
                Spacer()
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(accent ? LifeTheme.accent : LifeTheme.textTertiary) // // modified
            }
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(accent ? LifeTheme.accent : LifeTheme.textPrimary) // // modified
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)                   // // modified
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LifeTheme.glassFill)                                  // // modified
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent ? LifeTheme.accentMuted : LifeTheme.glassBorder, lineWidth: 0.5) // // modified
        )
    }
}

// MARK: - CountdownRow  // modified

struct CountdownRow: View {
    let icon: String
    var color: Color = LifeTheme.accent
    let label: String
    let count: Int
    let unit: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))                              // // modified
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            Spacer()
            Text("\(count.formatted())")
                .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            Text(unit)
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)                  // // modified
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

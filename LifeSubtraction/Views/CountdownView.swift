import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var store: LifeStore

    @State private var remainingMomentItems: [RemainingMomentItem] = []
    @State private var deletingItem: RemainingMomentItem?
    @State private var showingAddMoment = false

    private let momentColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    IntegratedTimeFlowCard(
                        birthday: store.birthday,
                        lifeExpectancy: store.lifeExpectancy
                    )
                    .padding(.horizontal)

                    remainingMomentsSection
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 16)
            }
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("倒數")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: RemainingMomentItem.self) { item in
                RemainingMomentDetailView(
                    item: item,
                    journeyStats: journeyStatsBinding,
                    journeyRecords: journeyRecordsBinding
                )
                .environmentObject(store)
            }
            .onAppear { loadAllData() }
            .sheet(isPresented: $showingAddMoment) {
                AddRemainingMomentView { newItem in
                    remainingMomentItems.append(newItem)
                    saveRemainingMomentItems()
                }
            }
            .alert(
                "刪除項目？",
                isPresented: Binding(
                    get: { deletingItem != nil },
                    set: { if !$0 { deletingItem = nil } }
                ),
                presenting: deletingItem
            ) { item in
                Button("刪除", role: .destructive) {
                    archiveRemainingMoment(item)
                    deletingItem = nil
                }
                Button("取消", role: .cancel) { deletingItem = nil }
            } message: { item in
                Text("「\(item.title)」將被移至封存。")
            }
        }
    }

    // MARK: - Remaining Moments（一排兩個）

    var remainingMomentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("你還有幾次？")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Button(action: { showingAddMoment = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            if activeRemainingMomentItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(LifeTheme.textTertiary)
                    Text("在總覽完成問卷，或手動新增項目")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 20)
            } else {
                LazyVGrid(columns: momentColumns, spacing: 12) {
                    ForEach(activeRemainingMomentItems) { item in
                        NavigationLink(value: item) {
                            momentGridCell(for: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { deletingItem = item } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    var activeRemainingMomentItems: [RemainingMomentItem] {
        remainingMomentItems.filter { !$0.isArchived }
    }

    func momentGridCell(for item: RemainingMomentItem) -> some View {
        let remaining = item.estimatedRemainingOccurrences(store: store, metrics: store.metrics)

        return VStack(alignment: .leading, spacing: 8) {
            Image(systemName: item.iconName)
                .font(.caption)
                .foregroundStyle(LifeTheme.accent)

            Text(item.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LifeTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(remaining.formatted())")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(LifeTheme.warm)
                Text(item.unit)
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            Text(item.frequency.displayName)
                .font(.caption2)
                .foregroundStyle(LifeTheme.textQuaternary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LifeTheme.glassFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
        )
    }

    private var journeyStatsBinding: Binding<[LifeJourneyStatItem]> {
        Binding(
            get: {
                LocalJSONStore.load(
                    [LifeJourneyStatItem].self,
                    key: StorageKey.lifeJourneyStatItems,
                    defaultValue: []
                )
            },
            set: { LocalJSONStore.save($0, key: StorageKey.lifeJourneyStatItems) }
        )
    }

    private var journeyRecordsBinding: Binding<[LifeJourneyStatRecord]> {
        Binding(
            get: {
                LocalJSONStore.load(
                    [LifeJourneyStatRecord].self,
                    key: StorageKey.lifeJourneyStatRecords,
                    defaultValue: []
                )
            },
            set: { LocalJSONStore.save($0, key: StorageKey.lifeJourneyStatRecords) }
        )
    }

    func archiveRemainingMoment(_ item: RemainingMomentItem) {
        guard let index = remainingMomentItems.firstIndex(where: { $0.id == item.id }) else { return }
        remainingMomentItems[index].isArchived = true
        saveRemainingMomentItems()
    }

    func saveRemainingMomentItems() {
        LocalJSONStore.save(remainingMomentItems, key: StorageKey.remainingMomentItems)
    }

    func loadAllData() {
        remainingMomentItems = LocalJSONStore.load(
            [RemainingMomentItem].self,
            key: StorageKey.remainingMomentItems,
            defaultValue: []
        )
        if RemainingMomentItem.migrateLegacyParentDependency(&remainingMomentItems) {
            saveRemainingMomentItems()
        }
    }
}

#Preview {
    CountdownView()
        .environmentObject(LifeStore())
}

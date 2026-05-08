import SwiftUI

// 修改内容 — 新增「你還有幾次？」項目，可關聯重要的人
struct AddRemainingMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager

    let onSave: (RemainingMomentItem) -> Void

    @State private var name = ""
    @State private var selectedIcon = "heart.fill"
    @State private var frequency: MomentFrequency = .monthly
    @State private var linkedMemberId: UUID? = nil

    @State private var familyMembers: [FamilyMember] = []
    @State private var showingAddFamilyMember = false
    @State private var showingPaywall = false

    var activeMembers: [FamilyMember] { familyMembers.filter { !$0.isArchived } }

    var body: some View {
        NavigationView {
            Form {
                Section("項目設定") {
                    TextField("項目名稱，例如：陪媽媽吃飯", text: $name)

                    Picker("頻率", selection: $frequency) {
                        ForEach(MomentFrequency.allCases) { f in
                            Text(f.displayName).tag(f)
                        }
                    }
                }

                Section("圖示") {
                    iconPicker
                }

                Section {
                    familyPickerContent
                } header: {
                    Text("關聯重要的人（選填）")
                } footer: {
                    Text("關聯後，剩餘次數將根據你們共同的時間計算。")
                }
            }
            .navigationTitle("新增項目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { loadFamilyMembers() }
            .sheet(isPresented: $showingAddFamilyMember) {
                AddFamilyMemberView { member in
                    familyMembers.append(member)
                    LocalJSONStore.save(familyMembers, key: AppConstants.Key.familyMembers)
                    linkedMemberId = member.id
                }
            }
            .sheet(isPresented: $showingPaywall) {
                FamilyPaywallView().environmentObject(storeManager)
            }
        }
    }

    // 修改内容 — 圖示選擇格
    var iconPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
            ForEach(RemainingMomentItem.availableIcons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedIcon == icon ? LifeTheme.accentSoft : Color.white.opacity(0.06))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .foregroundStyle(selectedIcon == icon ? LifeTheme.accent : LifeTheme.textSecondary)
                            .font(.system(size: 18))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // 修改内容 — 家人關聯選擇
    var familyPickerContent: some View {
        Group {
            // 「不關聯」選項
            Button {
                linkedMemberId = nil
            } label: {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                        .foregroundStyle(LifeTheme.textSecondary)
                        .frame(width: 24)
                    Text("不關聯")
                        .foregroundStyle(LifeTheme.textPrimary)
                    Spacer()
                    if linkedMemberId == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(LifeTheme.accent)
                            .font(.caption)
                    }
                }
            }
            .buttonStyle(.plain)

            // 現有家人
            ForEach(activeMembers) { member in
                Button {
                    linkedMemberId = member.id
                } label: {
                    HStack {
                        Image(systemName: member.relation.iconName)
                            .foregroundStyle(LifeTheme.accent)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(member.name)
                                .foregroundStyle(LifeTheme.textPrimary)
                            Text(member.relation.displayName)
                                .font(.caption2)
                                .foregroundStyle(LifeTheme.textSecondary)
                        }
                        Spacer()
                        if linkedMemberId == member.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(LifeTheme.accent)
                                .font(.caption)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // 新增家人按鈕
            Button {
                if storeManager.canAddFamilyMember(currentCount: activeMembers.count) {
                    showingAddFamilyMember = true
                } else {
                    showingPaywall = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LifeTheme.accent)
                    Text("新增重要的人")
                        .foregroundStyle(LifeTheme.accent)
                }
            }
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() {
        let item = RemainingMomentItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            frequency: frequency,
            linkedFamilyMemberId: linkedMemberId,
            createdAt: Date(),
            isArchived: false
        )
        onSave(item)
        dismiss()
    }

    func loadFamilyMembers() {
        familyMembers = LocalJSONStore.load(
            [FamilyMember].self,
            key: AppConstants.Key.familyMembers,
            defaultValue: []
        )
    }
}

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var store: LifeStore
    @EnvironmentObject var storeManager: StoreManager
    @State private var showPaywall = false
    @State private var showResetAlert = false

    var body: some View {
        NavigationView {
            // Form 改成 ScrollView 自繪卡片，配合暗色玻璃感  // modified
            ScrollView {
                VStack(spacing: 18) {
                    profileSection
                    familySection
                    subscriptionSection
                    notificationSection
                    aboutSection
                    resetSection
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)                              // // modified
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)               // // modified
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(storeManager)
            }
            .alert("確定重置？", isPresented: $showResetAlert) {
                Button("完整清除", role: .destructive) {
                    resetAllData()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("所有資料將被清除並回到 onboarding，此操作無法還原。")
            }
        }
    }

    // MARK: - Section header  // modified

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption).fontWeight(.medium)
            .foregroundStyle(LifeTheme.textTertiary)                       // // modified
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }

    // MARK: - 個人資料  // modified

    var profileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("個人資料")
            VStack(spacing: 0) {
                HStack {
                    Text("生日")
                        .foregroundStyle(LifeTheme.textPrimary)
                    Spacer()
                    DatePicker("", selection: $store.birthday, displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "zh_TW"))
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                rowDivider

                Stepper(
                    "預計壽命：\(store.lifeExpectancy) 歲",
                    value: $store.lifeExpectancy,
                    in: 60...120
                )
                .padding(.horizontal, 16).padding(.vertical, 14)
                .foregroundStyle(LifeTheme.textPrimary)                    // // modified
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
    }
    // MARK: - 家人  // 修改内容

    var familySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("家人資料")

            VStack(spacing: 0) {
                NavigationLink {
                    FamilyView()
                        .environmentObject(storeManager)
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(LifeTheme.accent)

                        Text("管理家人資料")
                            .foregroundStyle(LifeTheme.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(LifeTheme.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
    }

    // MARK: - 訂閱  // modified

    var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("訂閱狀態")
            VStack(spacing: 0) {
                if storeManager.isPremium {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(LifeTheme.accent)
                        Text("完整版").fontWeight(.medium)
                            .foregroundStyle(LifeTheme.textPrimary)
                        Spacer()
                        Text("已解鎖")
                            .foregroundStyle(LifeTheme.textSecondary)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                } else {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(LifeTheme.warm)
                        Text("免費版")
                            .foregroundStyle(LifeTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)

                    rowDivider
                    actionRow(title: "升級完整版 \(storeManager.formattedPrice)",
                              accent: true) { showPaywall = true }
                    rowDivider
                    actionRow(title: "還原購買") {
                        Task { await storeManager.restore() }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
    }

    // MARK: - 通知  // modified

    var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("通知")
            VStack(spacing: 0) {
                actionRow(title: "重新設定每日提醒", accent: true) {
                    NotificationManager.shared.scheduleDailyReminder()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
    }

    // MARK: - 關於  // modified

    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("關於")
            VStack(spacing: 0) {
                HStack {
                    Text("版本")
                        .foregroundStyle(LifeTheme.textPrimary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(LifeTheme.textSecondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                rowDivider
                Link(destination: URL(string: "https://yoursite.com/privacy")!) {
                    HStack {
                        Text("隱私政策")
                            .foregroundStyle(LifeTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(LifeTheme.textTertiary)
                            .font(.caption)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                }

                rowDivider
                Link(destination: URL(string: "https://yoursite.com/terms")!) {
                    HStack {
                        Text("使用條款")
                            .foregroundStyle(LifeTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(LifeTheme.textTertiary)
                            .font(.caption)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LifeTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
            )
        }
    }

    // MARK: - 重置  // modified

    var resetSection: some View {
        Button {
            showResetAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("重置所有資料")
            }
            .font(.subheadline).fontWeight(.medium)
            .foregroundStyle(Color.red.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.red.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.red.opacity(0.25), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Helpers  // modified

    var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    func actionRow(title: String, accent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(accent ? LifeTheme.accent : LifeTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }

    func resetAllData() {
        let keysToRemove = [
            AppConstants.Key.birthday,
            AppConstants.Key.lifeExpectancy,
            AppConstants.Key.onboarded,
            AppConstants.Key.values,
            AppConstants.Key.familyMembers,
            AppConstants.Key.familyMomentRecords,
            StorageKey.lifeGoals,
            StorageKey.regretItems,
            StorageKey.reflectionEntries,
            StorageKey.remainingMomentItems,
            StorageKey.remainingMomentRecords,
            StorageKey.lifeJourneyStatItems,
            StorageKey.lifeJourneyStatRecords,
            JourneyStatsBootstrap.questionnaireDoneKey,
            "parentAge",
            "parentLifeExpectancy",
            "data-migration-version"
        ]

        for key in keysToRemove {
            UserDefaults.shared.removeObject(forKey: key)
        }

        store.values = [
            LifeValue(name: "家人", icon: "house.fill"),
            LifeValue(name: "健康", icon: "heart.fill"),
            LifeValue(name: "成長", icon: "leaf.fill"),
        ]
        store.hasCompletedOnboarding = false
    }
}

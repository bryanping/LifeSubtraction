import SwiftUI

/// 目標期限設定、延後與狀態顯示。
struct GoalDueDateSection: View {
    @Binding var dueDate: Date?
    @Binding var originalDueDate: Date?
    @Binding var extensionCount: Int
    var isEditable: Bool
    var onUpdate: () -> Void

    @State private var showingPostponeSheet = false
    @State private var showingConfirmDeadline = false
    @State private var showingCancelDeadline = false
    @State private var isSettingUp = false
    @State private var draftDate = Date().addingTimeInterval(86400 * 30)

    private var isLocked: Bool {
        dueDate != nil && originalDueDate != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("目標期限")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                if isEditable {
                    Toggle("", isOn: deadlineToggleBinding)
                        .labelsHidden()
                        .tint(LifeTheme.accent)
                }
            }

            if isSettingUp {
                setupContent
            } else if let dueDate {
                lockedContent(dueDate: dueDate)
            } else if isEditable {
                Text("開啟後可設定完成期限，確認後僅能透過延後修改")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
        }
        .cardStyle()
        .onAppear(perform: syncFromModel)
        .confirmationDialog(
            "確認設定目標期限？",
            isPresented: $showingConfirmDeadline,
            titleVisibility: .visible
        ) {
            Button("確認設定") { commitDeadline() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("期限設為 \(formatDate(draftDate))，\(statusText(for: draftDate))。設定後只能透過「延後期限」修改。")
        }
        .confirmationDialog(
            "確定取消目標期限？",
            isPresented: $showingCancelDeadline,
            titleVisibility: .visible
        ) {
            Button("取消期限", role: .destructive) { clearDeadline() }
            Button("保留", role: .cancel) {}
        } message: {
            Text("將清除目前期限與延後紀錄。")
        }
        .sheet(isPresented: $showingPostponeSheet) {
            if let current = dueDate {
                GoalPostponeSheet(currentDueDate: current) { newDate in
                    guard newDate > current else { return }
                    dueDate = newDate
                    extensionCount += 1
                    onUpdate()
                }
            }
        }
    }

    // MARK: - Setup（尚未確認）

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(
                "完成期限",
                selection: $draftDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .tint(LifeTheme.accent)
            .foregroundStyle(LifeTheme.textPrimary)

            daysRemainingNote(for: draftDate)

            PrimaryButton("確認期限", icon: "checkmark.circle") {
                showingConfirmDeadline = true
            }
        }
    }

    // MARK: - Locked（已確認）

    @ViewBuilder
    private func lockedContent(dueDate: Date) -> some View {
        detailRow("完成期限", formatDate(dueDate))
        daysRemainingNote(for: dueDate)

        if let original = originalDueDate,
           !Calendar.current.isDate(original, inSameDayAs: dueDate) {
            detailRow("原先期限", formatDate(original))
        }

        if isEditable {
            SecondaryButton("延後期限", icon: "calendar.badge.plus") {
                showingPostponeSheet = true
            }

            if extensionCount > 0 {
                Text("已延後 \(extensionCount) 次")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }
        } else if extensionCount > 0 {
            detailRow("延後次數", "\(extensionCount) 次")
        }
    }

    private func daysRemainingNote(for date: Date) -> some View {
        let days = daysRemaining(until: date)
        return HStack(spacing: 6) {
            Image(systemName: statusIcon(days: days))
                .font(.caption)
            Text(statusText(days: days))
                .font(.caption)
        }
        .foregroundStyle(statusColor(days: days))
        .padding(.horizontal, 4)
    }

    private var deadlineToggleBinding: Binding<Bool> {
        Binding(
            get: { isSettingUp || dueDate != nil },
            set: { enabled in
                if enabled {
                    isSettingUp = true
                    draftDate = Date().addingTimeInterval(86400 * 30)
                } else if isLocked {
                    showingCancelDeadline = true
                } else {
                    isSettingUp = false
                    dueDate = nil
                    originalDueDate = nil
                    extensionCount = 0
                    onUpdate()
                }
            }
        )
    }

    private func commitDeadline() {
        dueDate = draftDate
        originalDueDate = draftDate
        extensionCount = 0
        isSettingUp = false
        onUpdate()
    }

    private func clearDeadline() {
        dueDate = nil
        originalDueDate = nil
        extensionCount = 0
        isSettingUp = false
        onUpdate()
    }

    private func syncFromModel() {
        if dueDate != nil {
            isSettingUp = false
            if let dueDate { draftDate = dueDate }
        } else {
            isSettingUp = false
        }
    }

    private func daysRemaining(until date: Date) -> Int {
        let cal = Calendar.current
        return cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: Date()),
            to: cal.startOfDay(for: date)
        ).day ?? 0
    }

    private func statusText(for date: Date) -> String {
        let days = daysRemaining(until: date)
        if days < 0 { return "已逾期 \(abs(days)) 天" }
        if days == 0 { return "今天到期" }
        return "還剩 \(days) 天"
    }

    private func statusText(days: Int) -> String {
        if days < 0 { return "已逾期 \(abs(days)) 天" }
        if days == 0 { return "今天到期" }
        return "還剩 \(days) 天"
    }

    private func statusIcon(days: Int) -> String {
        if days < 0 { return "exclamationmark.triangle.fill" }
        if days <= 3 { return "clock.badge.exclamationmark.fill" }
        return "calendar"
    }

    private func statusColor(days: Int) -> Color {
        if days < 0 { return .red.opacity(0.85) }
        if days <= 3 { return LifeTheme.warm }
        return LifeTheme.textTertiary
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(LifeTheme.textTertiary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

private struct GoalPostponeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentDueDate: Date
    let onConfirm: (Date) -> Void

    @State private var newDate: Date
    @State private var showingConfirm = false

    init(currentDueDate: Date, onConfirm: @escaping (Date) -> Void) {
        self.currentDueDate = currentDueDate
        self.onConfirm = onConfirm
        let defaultDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDueDate) ?? currentDueDate
        _newDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("目前期限：\(formatDate(currentDueDate))")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)

                DatePicker(
                    "延後至",
                    selection: $newDate,
                    in: currentDueDate.addingTimeInterval(86400)...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(LifeTheme.accent)

                postponeNote

                Spacer()
            }
            .padding()
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("延後期限")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認延後") { showingConfirm = true }
                }
            }
            .confirmationDialog(
                "確認延後期限？",
                isPresented: $showingConfirm,
                titleVisibility: .visible
            ) {
                Button("確認延後") {
                    onConfirm(newDate)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("由 \(formatDate(currentDueDate)) 延後至 \(formatDate(newDate))")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var postponeNote: some View {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: newDate)
        ).day ?? 0
        let text = days < 0 ? "已逾期 \(abs(days)) 天" : (days == 0 ? "今天到期" : "還剩 \(days) 天")
        return Text(text)
            .font(.caption)
            .foregroundStyle(LifeTheme.textTertiary)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

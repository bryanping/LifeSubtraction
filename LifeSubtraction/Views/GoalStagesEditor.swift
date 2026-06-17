import SwiftUI

/// 可編輯的階段清單：新增、修改、刪除、排序。
struct GoalStagesEditor: View {
    @Binding var stages: [GoalStage]
    var onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("進度步驟")
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Spacer()
                Button {
                    stages.append(GoalStage(title: "新步驟"))
                    onUpdate()
                } label: {
                    Label("新增", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LifeTheme.accent)
                }
            }

            if stages.isEmpty {
                Text("至少保留一個步驟")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)
            }

            ForEach($stages) { $stage in
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal")
                        .font(.caption)
                        .foregroundStyle(LifeTheme.textQuaternary)

                    TextField("步驟名稱", text: $stage.title)
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textPrimary)
                        .onChange(of: stage.title) { _, _ in onUpdate() }

                    Button(role: .destructive) {
                        stages.removeAll { $0.id == stage.id }
                        onUpdate()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.red.opacity(0.75))
                    }
                    .disabled(stages.count <= 1)
                }
                .padding(.vertical, 6)
            }

            Text("可依你的實際情況調整每個步驟")
                .font(.caption2)
                .foregroundStyle(LifeTheme.textTertiary)
        }
    }
}

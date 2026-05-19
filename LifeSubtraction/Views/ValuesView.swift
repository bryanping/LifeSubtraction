import SwiftUI

struct ValuesView: View {
    @EnvironmentObject var store: LifeStore
    @State private var showAddSheet = false
    @State private var newName = ""
    @State private var newIcon = "star"

    let iconOptions = ["star", "heart", "leaf", "bolt", "flame", "person.2", "house", "book", "music.note", "paintbrush", "sportscourt", "globe"]

    var body: some View {
        NavigationView {
            // List 改成 ScrollView + 自繪卡片，配合暗色玻璃感  // modified
            ScrollView {
                VStack(spacing: 14) {
                    Text("寫下你最重視的事物，讓每天的選擇都有方向。")
                        .font(.subheadline)
                        .foregroundStyle(LifeTheme.textSecondary)          // // modified
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ForEach($store.values) { $value in
                        ValueRow(value: $value, onDelete: { id in
                            store.values.removeAll { $0.id == id }
                        })
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
            .scrollContentBackground(.hidden)                              // // modified
            .background(LifeTheme.subtleBackground.ignoresSafeArea())
            .navigationTitle("我的價值觀")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)               // // modified
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(LifeTheme.accent)             // // modified
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addSheet
            }
        }
    }

    var addSheet: some View {
        NavigationView {
            ZStack {
                LifeTheme.subtleBackground.ignoresSafeArea()               // // modified

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("名稱")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(LifeTheme.textSecondary)
                        TextField("例如：家人、健康、創作", text: $newName)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LifeTheme.glassFill)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(LifeTheme.glassBorder, lineWidth: 0.5)
                            )
                            .foregroundStyle(LifeTheme.textPrimary)        // // modified

                        Text("圖示")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(LifeTheme.textSecondary)
                            .padding(.top, 8)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(newIcon == icon ? LifeTheme.accent : LifeTheme.textTertiary) // // modified
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(newIcon == icon ? LifeTheme.accentSoft : Color.white.opacity(0.04))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(newIcon == icon ? LifeTheme.accentMuted : LifeTheme.glassBorder, lineWidth: 0.5)
                                    )
                                    .onTapGesture { newIcon = icon }
                            }
                        }
                        .padding(.top, 4)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("新增價值觀")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showAddSheet = false
                        newName = ""
                    }
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("加入") {
                        guard !newName.isEmpty else { return }
                        store.values.append(LifeValue(name: newName, icon: newIcon))
                        showAddSheet = false
                        newName = ""
                        newIcon = "star"
                    }
                    .foregroundStyle(LifeTheme.accent)                     // // modified
                    .disabled(newName.isEmpty)
                }
            }
        }
    }
}

// MARK: - ValueRow  // modified — 自繪玻璃卡 + 展開反思

struct ValueRow: View {
    @Binding var value: LifeValue
    var onDelete: (UUID) -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LifeTheme.accentSoft)
                        .frame(width: 36, height: 36)
                    Image(systemName: value.icon)
                        .foregroundStyle(LifeTheme.accent)
                }
                Text(value.name)
                    .font(.body).fontWeight(.medium)
                    .foregroundStyle(LifeTheme.textPrimary)                // // modified
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textTertiary)               // // modified
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { expanded.toggle() } }

            if expanded {
                TextField("為什麼這對你重要？", text: $value.reflection, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textSecondary)              // // modified
                    .lineLimit(3...6)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )

                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        onDelete(value.id)
                    } label: {
                        Label("刪除", systemImage: "trash")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.red.opacity(0.85))               // // modified
                }
            }
        }
        .cardStyle()
    }
}

import SwiftUI

struct WatchReflectionView: View {
    let prompts = [
        "今天，你做了什麼值得的事？",
        "你最重視的人，今天有聯繫嗎？",
        "今天結束前，做一件讓未來的你感謝的事。",
        "現在這一刻，你想感謝誰？",
        "如果今天是這個月最後一天，你想做什麼？",
        "你現在可以放下哪一件不重要的事？"
    ]

    @State private var index: Int = Int.random(in: 0..<6)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("今日提問")
                    .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified

                Text(prompts[index % prompts.count])
                    .font(.system(.title3, design: .rounded))
                    .lineSpacing(4)

                Spacer(minLength: 8)

                Button {
                    withAnimation { index = (index + 1) % prompts.count }
                } label: {
                    Label("換一題", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .tint(LifeTheme.accent)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("反思")
    }
}

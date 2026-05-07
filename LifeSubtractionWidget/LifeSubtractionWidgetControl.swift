//
//  LifeSubtractionWidgetControl.swift
//  LifeSubtractionWidget
//
//  iOS 18+ 控制中心按鈕：點一下打開「人生減法」。
//

import AppIntents
import SwiftUI
import WidgetKit

struct LifeSubtractionWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.lifesubtraction.openApp"
        ) {
            ControlWidgetButton(action: OpenLifeSubtractionIntent()) {
                Label("人生減法", systemImage: "hourglass")
            }
        }
        .displayName("打開人生減法")
        .description("快速打開人生減法 App。")
    }
}

struct OpenLifeSubtractionIntent: AppIntent {
    static let title: LocalizedStringResource = "打開人生減法"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

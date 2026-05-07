//
//  LifeSubtractionWidgetBundle.swift
//  LifeSubtractionWidget
//

import WidgetKit
import SwiftUI

@main
struct LifeSubtractionWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeSubtractionWidget()       // 主：剩餘天數（small/medium/large + lock screen）
        LifeProgressWidget()          // 次：當前年/週進度
        LifeSubtractionWidgetControl() // iOS 18 控制中心（開啟 App）
        LifeSubtractionWidgetLiveActivity() // 預留（未啟用，App 沒呼叫 ActivityKit）
    }
}

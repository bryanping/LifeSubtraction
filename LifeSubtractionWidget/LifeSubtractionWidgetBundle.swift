//
//  LifeSubtractionWidgetBundle.swift
//  LifeSubtractionWidget
//

import WidgetKit
import SwiftUI

@main
struct LifeSubtractionWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeSubtractionWidget()
        LifeProgressWidget()
        FamilyReminderWidget()
        ReflectionPromptWidget()
        LifeSubtractionWidgetControl()
        LifeSubtractionWidgetLiveActivity()
    }
}

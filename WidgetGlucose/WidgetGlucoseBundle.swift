//
//  WidgetGlucoseBundle.swift
//  WidgetGlucose
//
//  Created by Victoria Marin on 08/06/25.

import WidgetKit
import SwiftUI

@main
struct HealthWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlucoseWidget()          // Regular widget for home screen
        GlucoseControlWidget()   // Control widget for Control Center
    }
}

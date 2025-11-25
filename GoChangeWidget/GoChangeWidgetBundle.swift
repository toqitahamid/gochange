//
//  GoChangeWidgetBundle.swift
//  GoChangeWidget
//
//  Created by Toqi Tahamid Sarker on 11/25/25.
//

import WidgetKit
import SwiftUI

@main
struct GoChangeWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoChangeWidget()
        GoChangeWidgetControl()
        GoChangeWidgetLiveActivity()
    }
}

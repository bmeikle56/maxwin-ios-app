//
//  AppSettings.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

struct AppSettings: Equatable, Codable, Sendable {
    var animationsEnabled: Bool
    var showYAxisLabels: Bool

    static let `default` = AppSettings(
        animationsEnabled: true,
        showYAxisLabels: true
    )
}

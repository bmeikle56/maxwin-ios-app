//
//  SettingsService.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

protocol SettingsServicing: AnyObject {
    var settings: AppSettings { get }
    func updateAnimationsEnabled(_ enabled: Bool)
}

@Observable
final class MockSettingsService: SettingsServicing {
    private let userDefaults: UserDefaults
    private let key = "app.settings.animationsEnabled"

    private(set) var settings: AppSettings

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if userDefaults.object(forKey: key) == nil {
            self.settings = .default
        } else {
            self.settings = AppSettings(animationsEnabled: userDefaults.bool(forKey: key))
        }
    }

    func updateAnimationsEnabled(_ enabled: Bool) {
        settings = AppSettings(animationsEnabled: enabled)
        userDefaults.set(enabled, forKey: key)
    }
}

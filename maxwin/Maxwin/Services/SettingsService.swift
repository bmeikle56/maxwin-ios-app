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
    func updateTipsEnabled(_ enabled: Bool)
    func updateCondensedSessionsList(_ enabled: Bool)
}

@Observable
final class MockSettingsService: SettingsServicing {
    private let userDefaults: UserDefaults
    private let settingsKey = "app.settings"
    private let legacyAnimationsKey = "app.settings.animationsEnabled"

    private(set) var settings: AppSettings

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else if userDefaults.object(forKey: legacyAnimationsKey) != nil {
            self.settings = AppSettings(
                animationsEnabled: userDefaults.bool(forKey: legacyAnimationsKey)
            )
            persist()
        } else {
            self.settings = .default
        }
    }

    func updateAnimationsEnabled(_ enabled: Bool) {
        settings.animationsEnabled = enabled
        persist()
    }

    func updateTipsEnabled(_ enabled: Bool) {
        settings.tipsEnabled = enabled
        persist()
    }

    func updateCondensedSessionsList(_ enabled: Bool) {
        settings.condensedSessionsList = enabled
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: settingsKey)
    }
}

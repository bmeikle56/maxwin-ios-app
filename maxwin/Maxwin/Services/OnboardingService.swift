//
//  OnboardingService.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

protocol OnboardingServicing: AnyObject {
    var hasCompletedOnboarding: Bool { get }
    func completeOnboarding()
    func resetOnboarding()
}

@Observable
final class MockOnboardingService: OnboardingServicing {
    private let userDefaults: UserDefaults
    private let key = "hasCompletedOnboarding"

    private(set) var hasCompletedOnboarding: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: key)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: key)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: key)
    }
}

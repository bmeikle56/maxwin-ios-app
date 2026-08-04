//
//  OnboardingViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    var hasAppeared = false

    private let onboardingService: OnboardingServicing

    init(onboardingService: OnboardingServicing) {
        self.onboardingService = onboardingService
    }

    func markAppeared() {
        hasAppeared = true
    }

    func getStarted() {
        onboardingService.completeOnboarding()
    }
}

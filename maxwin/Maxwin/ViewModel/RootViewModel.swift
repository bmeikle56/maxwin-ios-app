//
//  RootViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class RootViewModel {
    let authService: MockAuthService
    let onboardingService: MockOnboardingService

    let onboardingViewModel: OnboardingViewModel
    let loginViewModel: LoginViewModel
    let homeViewModel: HomeViewModel

    var hasCompletedOnboarding: Bool {
        onboardingService.hasCompletedOnboarding
    }

    var isAuthenticated: Bool {
        authService.isAuthenticated
    }

    init(authService: MockAuthService, onboardingService: MockOnboardingService) {
        self.authService = authService
        self.onboardingService = onboardingService
        self.onboardingViewModel = OnboardingViewModel(onboardingService: onboardingService)
        self.loginViewModel = LoginViewModel(authService: authService)
        self.homeViewModel = HomeViewModel(authService: authService)
    }
}

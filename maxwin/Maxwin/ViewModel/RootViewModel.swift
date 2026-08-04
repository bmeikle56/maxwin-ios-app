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
    let settingsService: MockSettingsService
    let sessionService: MockSessionService
    let earningsService: MockEarningsService

    let onboardingViewModel: OnboardingViewModel
    let loginViewModel: LoginViewModel
    let mainTabViewModel: MainTabViewModel

    init(
        authService: MockAuthService = MockAuthService(),
        onboardingService: MockOnboardingService = MockOnboardingService(),
        settingsService: MockSettingsService = MockSettingsService(),
        sessionService: MockSessionService = MockSessionService(),
        earningsService: MockEarningsService? = nil
    ) {
        let earnings = earningsService ?? MockEarningsService(sessionService: sessionService)

        self.authService = authService
        self.onboardingService = onboardingService
        self.settingsService = settingsService
        self.sessionService = sessionService
        self.earningsService = earnings

        self.onboardingViewModel = OnboardingViewModel(onboardingService: onboardingService)
        self.loginViewModel = LoginViewModel(authService: authService)
        self.mainTabViewModel = MainTabViewModel(
            authService: authService,
            sessionService: sessionService,
            earningsService: earnings,
            settingsService: settingsService
        )
    }
}

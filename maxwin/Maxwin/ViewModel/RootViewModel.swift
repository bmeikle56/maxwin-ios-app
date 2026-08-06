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
    let biometricService: BiometricAuthService
    let onboardingService: MockOnboardingService
    let settingsService: MockSettingsService
    let sessionService: MockSessionService
    let trackDataService: MockTrackDataService

    let onboardingViewModel: OnboardingViewModel
    let loginViewModel: LoginViewModel
    let signUpViewModel: SignUpViewModel
    let mainTabViewModel: MainTabViewModel

    init(
        authService: MockAuthService = MockAuthService(),
        biometricService: BiometricAuthService = BiometricAuthService(),
        onboardingService: MockOnboardingService = MockOnboardingService(),
        settingsService: MockSettingsService = MockSettingsService(),
        sessionService: MockSessionService = MockSessionService(),
        trackDataService: MockTrackDataService? = nil
    ) {
        let trackData = trackDataService ?? MockTrackDataService(sessionService: sessionService)

        self.authService = authService
        self.biometricService = biometricService
        self.onboardingService = onboardingService
        self.settingsService = settingsService
        self.sessionService = sessionService
        self.trackDataService = trackData

        self.onboardingViewModel = OnboardingViewModel(onboardingService: onboardingService)
        self.loginViewModel = LoginViewModel(
            authService: authService,
            biometricService: biometricService,
            trackDataService: trackData
        )
        self.signUpViewModel = SignUpViewModel(
            authService: authService,
            biometricService: biometricService,
            trackDataService: trackData
        )
        self.mainTabViewModel = MainTabViewModel(
            authService: authService,
            sessionService: sessionService,
            trackDataService: trackData,
            settingsService: settingsService,
            biometricService: biometricService
        )

        // Restored sessions should warm the Track cache before the tab appears.
        if authService.isAuthenticated {
            Task { await trackData.prefetch() }
        }
    }
}

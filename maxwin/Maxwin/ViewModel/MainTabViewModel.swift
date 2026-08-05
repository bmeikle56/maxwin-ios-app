//
//  MainTabViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

enum MainTab: Hashable {
    case sessions
    case track
    case settings
}

@Observable
@MainActor
final class MainTabViewModel {
    var selectedTab: MainTab = .track

    let sessionsViewModel: SessionsViewModel
    let trackViewModel: TrackViewModel
    let settingsViewModel: SettingsViewModel

    private let settingsService: MockSettingsService

    init(
        authService: AuthServicing,
        sessionService: SessionServicing,
        earningsService: EarningsServicing,
        settingsService: MockSettingsService
    ) {
        self.settingsService = settingsService
        self.sessionsViewModel = SessionsViewModel(sessionService: sessionService)
        self.trackViewModel = TrackViewModel(
            earningsService: earningsService,
            sessionService: sessionService,
            animationsEnabled: settingsService.settings.animationsEnabled,
            showYAxisLabels: settingsService.settings.showYAxisLabels
        )
        self.settingsViewModel = SettingsViewModel(
            authService: authService,
            settingsService: settingsService
        )
    }

    func syncAnimationPreference() {
        trackViewModel.animationsEnabled = settingsService.settings.animationsEnabled
        trackViewModel.showYAxisLabels = settingsService.settings.showYAxisLabels
    }
}

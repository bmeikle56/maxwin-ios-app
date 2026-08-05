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
        trackDataService: TrackDataServicing,
        settingsService: MockSettingsService
    ) {
        self.settingsService = settingsService
        self.sessionsViewModel = SessionsViewModel(
            sessionService: sessionService,
            trackDataService: trackDataService
        )
        let trackViewModel = TrackViewModel(
            trackDataService: trackDataService,
            animationsEnabled: settingsService.settings.animationsEnabled,
            tipsEnabled: settingsService.settings.tipsEnabled
        )
        self.trackViewModel = trackViewModel
        self.settingsViewModel = SettingsViewModel(
            authService: authService,
            settingsService: settingsService,
            trackDataService: trackDataService
        )

        sessionsViewModel.onTrackDataChanged = { [weak trackViewModel] in
            trackViewModel?.reloadFromCache()
        }
    }

    func syncPreferences() {
        trackViewModel.animationsEnabled = settingsService.settings.animationsEnabled
        trackViewModel.tipsEnabled = settingsService.settings.tipsEnabled
    }
}

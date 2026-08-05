//
//  MainTabView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct MainTabView: View {
    @Bindable var viewModel: MainTabViewModel

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            SessionsView(viewModel: viewModel.sessionsViewModel)
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }
                .tag(MainTab.sessions)

            TrackView(
                viewModel: viewModel.trackViewModel,
                isSelected: viewModel.selectedTab == .track
            )
                .tabItem {
                    Label("Track", systemImage: "chart.xyaxis.line")
                }
                .tag(MainTab.track)

            SettingsView(
                viewModel: viewModel.settingsViewModel,
                onAnimationPreferenceChanged: {
                    viewModel.syncAnimationPreference()
                }
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(MainTab.settings)
        }
        .tint(MaxwinTheme.cream)
        .toolbarBackground(MaxwinTheme.feltDeep, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    MainTabView(
        viewModel: MainTabViewModel(
            authService: MockAuthService(),
            sessionService: MockSessionService(),
            trackDataService: MockTrackDataService(sessionService: MockSessionService()),
            settingsService: MockSettingsService()
        )
    )
}

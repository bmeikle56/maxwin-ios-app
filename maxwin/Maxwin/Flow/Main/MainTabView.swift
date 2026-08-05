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
        @Bindable var sessionsViewModel = viewModel.sessionsViewModel

        TabView(selection: $viewModel.selectedTab) {
            SessionsView(viewModel: sessionsViewModel)
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }
                .tag(MainTab.sessions)

            TrackView(
                viewModel: viewModel.trackViewModel,
                sessionsViewModel: sessionsViewModel,
                isSelected: viewModel.selectedTab == .track
            )
                .tabItem {
                    Label("Track", systemImage: "chart.xyaxis.line")
                }
                .tag(MainTab.track)

            SettingsView(
                viewModel: viewModel.settingsViewModel,
                onPreferenceChanged: {
                    viewModel.syncPreferences()
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
        .sheet(isPresented: $sessionsViewModel.isEditorPresented) {
            if let editorViewModel = sessionsViewModel.editorViewModel {
                SessionEditorView(viewModel: editorViewModel) {
                    await sessionsViewModel.handleEditorSaved()
                }
            }
        }
        .fullScreenCover(isPresented: $sessionsViewModel.isLiveSessionPresented) {
            if let liveSessionViewModel = sessionsViewModel.liveSessionViewModel {
                LiveSessionView(
                    viewModel: liveSessionViewModel,
                    onSave: {
                        await sessionsViewModel.saveLiveSession()
                    },
                    onDiscard: {
                        sessionsViewModel.discardLiveSession()
                    }
                )
            }
        }
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

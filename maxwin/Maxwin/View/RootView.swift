//
//  RootView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct RootView: View {
    @Bindable var viewModel: RootViewModel

    var body: some View {
        Group {
            if !viewModel.onboardingService.hasCompletedOnboarding {
                OnboardingView(viewModel: viewModel.onboardingViewModel)
            } else if viewModel.authService.isAuthenticated {
                HomeView(viewModel: viewModel.homeViewModel)
            } else {
                LoginView(viewModel: viewModel.loginViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.onboardingService.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: viewModel.authService.isAuthenticated)
    }
}

#Preview {
    RootView(
        viewModel: RootViewModel(
            authService: MockAuthService(),
            onboardingService: MockOnboardingService()
        )
    )
}

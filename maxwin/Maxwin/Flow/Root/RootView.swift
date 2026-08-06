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
        @Bindable var loginViewModel = viewModel.loginViewModel

        Group {
            if !viewModel.onboardingService.hasCompletedOnboarding {
                OnboardingView(viewModel: viewModel.onboardingViewModel)
            } else if viewModel.authService.isAuthenticated {
                MainTabView(viewModel: viewModel.mainTabViewModel)
            } else {
                LoginView(viewModel: loginViewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MaxwinTheme.felt.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: viewModel.onboardingService.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: viewModel.authService.isAuthenticated)
        .alert(
            "Enable \(loginViewModel.biometricsDisplayName)?",
            isPresented: $loginViewModel.showBiometricsPrompt
        ) {
            Button("Enable") {
                loginViewModel.enableBiometricsFromPrompt()
            }
            Button("Not Now", role: .cancel) {
                loginViewModel.declineBiometricsFromPrompt()
            }
        } message: {
            Text("Use \(loginViewModel.biometricsDisplayName) to sign in quickly the next time you open Maxwin.")
        }
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

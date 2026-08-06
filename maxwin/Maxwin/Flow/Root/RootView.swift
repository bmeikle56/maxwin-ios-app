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
        @Bindable var signUpViewModel = viewModel.signUpViewModel

        Group {
            if !viewModel.onboardingService.hasCompletedOnboarding {
                OnboardingView(viewModel: viewModel.onboardingViewModel)
            } else if viewModel.authService.isAuthenticated {
                MainTabView(viewModel: viewModel.mainTabViewModel)
            } else {
                NavigationStack {
                    LoginView(
                        viewModel: loginViewModel,
                        signUpViewModel: signUpViewModel
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MaxwinTheme.felt.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: viewModel.onboardingService.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: viewModel.authService.isAuthenticated)
        .alert(
            "Enable \(biometricsDisplayName)?",
            isPresented: biometricsPromptBinding
        ) {
            Button("Enable") {
                if loginViewModel.showBiometricsPrompt {
                    loginViewModel.enableBiometricsFromPrompt()
                } else {
                    signUpViewModel.enableBiometricsFromPrompt()
                }
            }
            Button("Not Now", role: .cancel) {
                if loginViewModel.showBiometricsPrompt {
                    loginViewModel.declineBiometricsFromPrompt()
                } else {
                    signUpViewModel.declineBiometricsFromPrompt()
                }
            }
        } message: {
            Text("Use \(biometricsDisplayName) to sign in quickly the next time you open Maxwin.")
        }
    }

    private var biometricsDisplayName: String {
        if viewModel.loginViewModel.showBiometricsPrompt {
            return viewModel.loginViewModel.biometricsDisplayName
        }
        return viewModel.signUpViewModel.biometricsDisplayName
    }

    private var biometricsPromptBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.loginViewModel.showBiometricsPrompt
                    || viewModel.signUpViewModel.showBiometricsPrompt
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.loginViewModel.showBiometricsPrompt = false
                    viewModel.signUpViewModel.showBiometricsPrompt = false
                }
            }
        )
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

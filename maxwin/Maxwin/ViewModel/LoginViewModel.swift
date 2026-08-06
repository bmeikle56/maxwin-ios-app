//
//  LoginViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var username = ""
    var password = ""
    var errorMessage: String?
    var showForgotPasswordAlert = false
    var forgotPasswordMessage = ""
    var showBiometricsPrompt = false
    var isLoading = false
    var isBiometricUnlockInProgress = false

    private let authService: AuthServicing
    private let biometricService: BiometricAuthServicing
    private let trackDataService: TrackDataServicing
    private var hasAttemptedBiometricUnlock = false

    var biometricsDisplayName: String {
        biometricService.biometricsDisplayName
    }

    var canOfferBiometricLogin: Bool {
        biometricService.isBiometricsEnabled
            && biometricService.canUseBiometrics
            && authService.isAwaitingBiometricUnlock
    }

    init(
        authService: AuthServicing,
        biometricService: BiometricAuthServicing,
        trackDataService: TrackDataServicing
    ) {
        self.authService = authService
        self.biometricService = biometricService
        self.trackDataService = trackDataService

        if authService.isAwaitingBiometricUnlock {
            username = authService.currentUser?.username ?? ""
        }
    }

    func prepareOnAppear() async {
        guard canOfferBiometricLogin, !hasAttemptedBiometricUnlock else { return }
        hasAttemptedBiometricUnlock = true
        await unlockWithBiometrics()
    }

    func unlockWithBiometrics() async {
        guard biometricService.isBiometricsEnabled,
              biometricService.canUseBiometrics,
              authService.isAwaitingBiometricUnlock else { return }

        errorMessage = nil
        isBiometricUnlockInProgress = true
        defer { isBiometricUnlockInProgress = false }

        do {
            try await biometricService.authenticate(
                reason: "Sign in to Maxwin with \(biometricService.biometricsDisplayName)"
            )
            authService.unlockWithBiometrics()
            await trackDataService.prefetch()
        } catch BiometricAuthError.cancelled {
            // Stay on login so the user can enter a password instead.
        } catch let error as BiometricAuthError {
            if let message = error.errorDescription {
                errorMessage = message
            }
        } catch {
            errorMessage = BiometricAuthError.failed.errorDescription
        }
    }

    func signIn() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let credentials = AuthCredentials(username: username, password: password)

        do {
            _ = try await authService.signIn(with: credentials)
            await trackDataService.prefetch()
            offerBiometricsPromptIfNeeded()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = AuthError.unknown.localizedDescription
        }
    }

    func enableBiometricsFromPrompt() {
        biometricService.setBiometricsEnabled(true)
        showBiometricsPrompt = false
    }

    func declineBiometricsFromPrompt() {
        biometricService.setBiometricsEnabled(false)
        showBiometricsPrompt = false
    }

    func forgotPasswordTapped() {
        Task {
            await requestPasswordReset()
        }
    }

    private func offerBiometricsPromptIfNeeded() {
        guard !biometricService.hasPromptedForBiometrics,
              biometricService.canUseBiometrics else { return }
        Task {
            // Let the post-login transition settle before presenting the alert.
            try? await Task.sleep(nanoseconds: 400_000_000)
            showBiometricsPrompt = true
        }
    }

    private func requestPasswordReset() async {
        do {
            try await authService.requestPasswordReset(for: username)
            forgotPasswordMessage = "If an account exists for that username, reset instructions will be sent. (Mocked — no email is sent yet.)"
        } catch let error as AuthError where error == .emptyFields {
            forgotPasswordMessage = "Enter your username above, then try Forgot Password again."
        } catch {
            forgotPasswordMessage = AuthError.unknown.localizedDescription
        }
        showForgotPasswordAlert = true
    }
}

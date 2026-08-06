//
//  SignUpViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/6/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class SignUpViewModel {
    var username = ""
    var password = ""
    var confirmPassword = ""
    var errorMessage: String?
    var showBiometricsPrompt = false
    var isLoading = false

    private let authService: AuthServicing
    private let biometricService: BiometricAuthServicing
    private let trackDataService: TrackDataServicing

    var biometricsDisplayName: String {
        biometricService.biometricsDisplayName
    }

    init(
        authService: AuthServicing,
        biometricService: BiometricAuthServicing,
        trackDataService: TrackDataServicing
    ) {
        self.authService = authService
        self.biometricService = biometricService
        self.trackDataService = trackDataService
    }

    func signUp() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            errorMessage = AuthError.emptyFields.localizedDescription
            return
        }

        guard password == confirmPassword else {
            errorMessage = AuthError.passwordMismatch.localizedDescription
            return
        }

        let credentials = AuthCredentials(username: username, password: password)

        do {
            _ = try await authService.signUp(with: credentials)
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

    private func offerBiometricsPromptIfNeeded() {
        guard !biometricService.hasPromptedForBiometrics,
              biometricService.canUseBiometrics else { return }
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            showBiometricsPrompt = true
        }
    }
}

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
    var isLoading = false

    private let authService: AuthServicing

    init(authService: AuthServicing) {
        self.authService = authService
    }

    func signIn() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let credentials = AuthCredentials(username: username, password: password)

        do {
            _ = try await authService.signIn(with: credentials)
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = AuthError.unknown.localizedDescription
        }
    }

    func forgotPasswordTapped() {
        Task {
            await requestPasswordReset()
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

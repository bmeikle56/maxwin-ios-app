//
//  EditProfileViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class EditProfileViewModel {
    var username: String
    var isSaving = false
    var errorMessage: String?

    private let authService: AuthServicing
    private let originalUsername: String

    var canSave: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != originalUsername && !isSaving
    }

    init(authService: AuthServicing) {
        self.authService = authService
        let current = authService.currentUser?.username ?? ""
        self.originalUsername = current
        self.username = current
    }

    /// Returns `true` when the profile was saved successfully.
    @discardableResult
    func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await authService.updateUsername(username)
            return true
        } catch AuthError.emptyFields {
            errorMessage = "Enter a username to continue."
            return false
        } catch {
            errorMessage = "Couldn't update profile. Try again."
            return false
        }
    }
}

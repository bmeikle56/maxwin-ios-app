//
//  AuthService.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

protocol AuthServicing: AnyObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    /// True when a saved session exists but biometrics must unlock it first.
    var isAwaitingBiometricUnlock: Bool { get }

    func signIn(with credentials: AuthCredentials) async throws -> User
    func unlockWithBiometrics()
    func updateUsername(_ username: String) async throws -> User
    func updatePassword(current: String, new: String) async throws
    func updateAvatar(imageData: Data?) async throws -> User
    func signOut() async
    func deleteAccount() async throws
    func requestPasswordReset(for username: String) async throws
}

@Observable
final class MockAuthService: AuthServicing {
    private let userDefaults: UserDefaults
    private let userKey = "auth.currentUser"
    private let passwordKey = "auth.password"
    private let isAuthenticatedKey = "auth.isAuthenticated"

    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool
    private(set) var isAwaitingBiometricUnlock = false
    private var storedPassword: String?

    /// Artificial delay so the UI can exercise loading states.
    var networkDelayNanoseconds: UInt64 = 450_000_000

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let biometricsEnabled = userDefaults.bool(forKey: BiometricAuthService.enabledKey)

        if userDefaults.bool(forKey: isAuthenticatedKey),
           let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.storedPassword = userDefaults.string(forKey: passwordKey)
            // When biometrics is on, keep the saved session but require unlock on open.
            if biometricsEnabled {
                self.isAuthenticated = false
                self.isAwaitingBiometricUnlock = true
            } else {
                self.isAuthenticated = true
                self.isAwaitingBiometricUnlock = false
            }
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
            self.isAwaitingBiometricUnlock = false
            self.storedPassword = nil
        }
    }

    func signIn(with credentials: AuthCredentials) async throws -> User {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        guard credentials.isValid else {
            throw AuthError.emptyFields
        }

        // Mock: accept any non-empty username/password pair.
        // Prefer restoring the existing user when unlocking a saved biometric session.
        let user: User
        if let currentUser,
           currentUser.username.caseInsensitiveCompare(credentials.trimmedUsername) == .orderedSame {
            user = currentUser
        } else {
            user = User(id: UUID(), username: credentials.trimmedUsername)
        }
        persist(user: user, password: credentials.password)
        return user
    }

    func unlockWithBiometrics() {
        guard currentUser != nil else { return }
        isAuthenticated = true
        isAwaitingBiometricUnlock = false
        userDefaults.set(true, forKey: isAuthenticatedKey)
    }

    func updateUsername(_ username: String) async throws -> User {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AuthError.emptyFields
        }
        guard let currentUser else {
            throw AuthError.unknown
        }

        let updated = User(
            id: currentUser.id,
            username: trimmed,
            avatarFileName: currentUser.avatarFileName
        )
        persist(user: updated, password: storedPassword)
        return updated
    }

    func updatePassword(current: String, new: String) async throws {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        guard currentUser != nil else {
            throw AuthError.unknown
        }
        guard !current.isEmpty, !new.isEmpty else {
            throw AuthError.emptyFields
        }

        // Sessions signed in before password persistence have no stored password;
        // accept any non-empty current password in that case.
        if let storedPassword, storedPassword != current {
            throw AuthError.incorrectPassword
        }

        persist(user: currentUser, password: new)
    }

    func updateAvatar(imageData: Data?) async throws -> User {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        guard let currentUser else {
            throw AuthError.unknown
        }

        ProfileAvatarStore.delete(fileName: currentUser.avatarFileName)

        let fileName: String?
        if let imageData {
            fileName = try ProfileAvatarStore.save(imageData: imageData, userID: currentUser.id)
        } else {
            fileName = nil
        }

        let updated = User(
            id: currentUser.id,
            username: currentUser.username,
            avatarFileName: fileName
        )
        persist(user: updated, password: storedPassword)
        return updated
    }

    func signOut() async {
        try? await Task.sleep(nanoseconds: networkDelayNanoseconds / 2)
        clearSession()
    }

    func deleteAccount() async throws {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)
        // Mock: wipe local session as if the account was removed.
        clearSession()
    }

    func requestPasswordReset(for username: String) async throws {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AuthError.emptyFields
        }
        // Mock: always succeeds once a username is provided.
    }

    private func persist(user: User?, password: String?) {
        currentUser = user
        storedPassword = password
        isAuthenticated = user != nil
        isAwaitingBiometricUnlock = false
        if let user, let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: userKey)
        } else {
            userDefaults.removeObject(forKey: userKey)
        }
        if let password {
            userDefaults.set(password, forKey: passwordKey)
        } else {
            userDefaults.removeObject(forKey: passwordKey)
        }
        userDefaults.set(isAuthenticated, forKey: isAuthenticatedKey)
    }

    private func clearSession() {
        ProfileAvatarStore.delete(fileName: currentUser?.avatarFileName)
        persist(user: nil, password: nil)
    }
}

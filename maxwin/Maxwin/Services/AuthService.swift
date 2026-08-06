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

    func signIn(with credentials: AuthCredentials) async throws -> User
    func updateUsername(_ username: String) async throws -> User
    func updateAvatar(imageData: Data?) async throws -> User
    func signOut() async
    func deleteAccount() async throws
    func requestPasswordReset(for username: String) async throws
}

@Observable
final class MockAuthService: AuthServicing {
    private let userDefaults: UserDefaults
    private let userKey = "auth.currentUser"
    private let isAuthenticatedKey = "auth.isAuthenticated"

    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool

    /// Artificial delay so the UI can exercise loading states.
    var networkDelayNanoseconds: UInt64 = 450_000_000

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if userDefaults.bool(forKey: isAuthenticatedKey),
           let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    func signIn(with credentials: AuthCredentials) async throws -> User {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        guard credentials.isValid else {
            throw AuthError.emptyFields
        }

        // Mock: accept any non-empty username/password pair.
        let user = User(id: UUID(), username: credentials.trimmedUsername)
        persist(user: user)
        return user
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
        persist(user: updated)
        return updated
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
        persist(user: updated)
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

    private func persist(user: User) {
        currentUser = user
        isAuthenticated = true
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: userKey)
        }
        userDefaults.set(true, forKey: isAuthenticatedKey)
    }

    private func clearSession() {
        ProfileAvatarStore.delete(fileName: currentUser?.avatarFileName)
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: userKey)
        userDefaults.set(false, forKey: isAuthenticatedKey)
    }
}

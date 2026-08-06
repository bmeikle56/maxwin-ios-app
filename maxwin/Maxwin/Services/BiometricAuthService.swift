//
//  BiometricAuthService.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/5/26.
//

import Foundation
import LocalAuthentication
import Observation

enum BiometricAuthError: LocalizedError, Equatable {
    case unavailable
    case failed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Biometrics aren’t available on this device."
        case .failed:
            return "Biometric authentication failed. Try again or sign in with your password."
        case .cancelled:
            return nil
        }
    }
}

protocol BiometricAuthServicing: AnyObject {
    var isBiometricsEnabled: Bool { get }
    var hasPromptedForBiometrics: Bool { get }
    var canUseBiometrics: Bool { get }
    var biometricsDisplayName: String { get }

    func setBiometricsEnabled(_ enabled: Bool)
    func markBiometricsPrompted()
    func authenticate(reason: String) async throws
}

@Observable
final class BiometricAuthService: BiometricAuthServicing {
    static let enabledKey = "auth.biometricsEnabled"
    static let promptedKey = "auth.biometricsPrompted"

    private let userDefaults: UserDefaults

    private(set) var isBiometricsEnabled: Bool
    private(set) var hasPromptedForBiometrics: Bool

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isBiometricsEnabled = userDefaults.bool(forKey: Self.enabledKey)
        self.hasPromptedForBiometrics = userDefaults.bool(forKey: Self.promptedKey)
    }

    var canUseBiometrics: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometricsDisplayName: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Biometrics"
        }
    }

    func setBiometricsEnabled(_ enabled: Bool) {
        isBiometricsEnabled = enabled
        userDefaults.set(enabled, forKey: Self.enabledKey)
        markBiometricsPrompted()
    }

    func markBiometricsPrompted() {
        hasPromptedForBiometrics = true
        userDefaults.set(true, forKey: Self.promptedKey)
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricAuthError.unavailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            guard success else {
                throw BiometricAuthError.failed
            }
        } catch let error as BiometricAuthError {
            throw error
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricAuthError.cancelled
            case .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
                throw BiometricAuthError.unavailable
            default:
                throw BiometricAuthError.failed
            }
        } catch {
            throw BiometricAuthError.failed
        }
    }
}

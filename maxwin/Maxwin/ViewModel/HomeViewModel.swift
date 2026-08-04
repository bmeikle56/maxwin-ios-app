//
//  HomeViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var isSigningOut = false

    private let authService: AuthServicing

    var welcomeName: String {
        authService.currentUser?.username ?? ""
    }

    var welcomeTitle: String {
        welcomeName.isEmpty ? "Welcome" : "Welcome, \(welcomeName)"
    }

    init(authService: AuthServicing) {
        self.authService = authService
    }

    func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        await authService.signOut()
    }
}

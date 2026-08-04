//
//  AuthCredentials.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

struct AuthCredentials: Equatable, Sendable {
    let username: String
    let password: String

    var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedUsername.isEmpty && !password.isEmpty
    }
}

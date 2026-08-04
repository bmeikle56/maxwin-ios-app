//
//  AuthError.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case emptyFields
    case networkUnavailable
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Incorrect username or password."
        case .emptyFields:
            return "Enter a username and password to continue."
        case .networkUnavailable:
            return "Unable to reach the server. Try again."
        case .unknown:
            return "Something went wrong. Try again."
        }
    }
}

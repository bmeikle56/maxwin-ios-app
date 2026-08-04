//
//  User.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

struct User: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let username: String
}

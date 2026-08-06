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
    /// Filename under the local avatars directory, when the user has set a photo.
    var avatarFileName: String?

    init(id: UUID, username: String, avatarFileName: String? = nil) {
        self.id = id
        self.username = username
        self.avatarFileName = avatarFileName
    }
}

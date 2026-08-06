//
//  AppSettings.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

struct AppSettings: Equatable, Codable, Sendable {
    var animationsEnabled: Bool
    var tipsEnabled: Bool
    var condensedSessionsList: Bool

    static let `default` = AppSettings(
        animationsEnabled: true,
        tipsEnabled: true,
        condensedSessionsList: false
    )

    private enum CodingKeys: String, CodingKey {
        case animationsEnabled
        case tipsEnabled
        case condensedSessionsList
    }

    init(
        animationsEnabled: Bool,
        tipsEnabled: Bool = true,
        condensedSessionsList: Bool = false
    ) {
        self.animationsEnabled = animationsEnabled
        self.tipsEnabled = tipsEnabled
        self.condensedSessionsList = condensedSessionsList
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        animationsEnabled = try container.decode(Bool.self, forKey: .animationsEnabled)
        tipsEnabled = try container.decodeIfPresent(Bool.self, forKey: .tipsEnabled) ?? true
        condensedSessionsList = try container.decodeIfPresent(Bool.self, forKey: .condensedSessionsList) ?? false
    }
}

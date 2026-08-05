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

    static let `default` = AppSettings(
        animationsEnabled: true,
        tipsEnabled: true
    )

    private enum CodingKeys: String, CodingKey {
        case animationsEnabled
        case tipsEnabled
    }

    init(animationsEnabled: Bool, tipsEnabled: Bool = true) {
        self.animationsEnabled = animationsEnabled
        self.tipsEnabled = tipsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        animationsEnabled = try container.decode(Bool.self, forKey: .animationsEnabled)
        tipsEnabled = try container.decodeIfPresent(Bool.self, forKey: .tipsEnabled) ?? true
    }
}

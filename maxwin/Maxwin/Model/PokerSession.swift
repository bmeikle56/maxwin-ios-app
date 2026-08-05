//
//  PokerSession.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

enum GameType: String, Codable, Sendable, CaseIterable {
    case cash = "Cash"
    case tournament = "Tournament"
}

struct PokerSession: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let date: Date
    let venue: String
    let gameType: GameType
    let stakes: String
    let durationMinutes: Int
    let buyIn: Double
    let cashOut: Double
    let hands: [Hand]
    var isFavorite: Bool = false

    var profit: Double { cashOut - buyIn }

    /// Big blind parsed from common stake strings like `2/5 NL` or `25NL`.
    var bigBlind: Double? {
        StakesParsing.bigBlind(from: stakes)
    }

    var formattedDuration: String {
        Self.formatDuration(minutes: durationMinutes)
    }

    static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
}

enum StakesParsing {
    /// Extracts the big blind from cash stake text. Returns nil for buy-in / unknown formats.
    static func bigBlind(from stakes: String) -> Double? {
        let trimmed = stakes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let slash = trimmed.range(of: #"(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)"#, options: .regularExpression) {
            let match = String(trimmed[slash])
            let parts = match.split(whereSeparator: { $0 == "/" || $0.isWhitespace })
                .compactMap { Double($0) }
            if parts.count >= 2, parts[1] > 0 {
                return parts[1]
            }
        }

        if let nl = trimmed.range(of: #"(\d+(?:\.\d+)?)\s*NL\b"#, options: [.regularExpression, .caseInsensitive]) {
            let match = String(trimmed[nl])
            let digits = match.prefix { $0.isNumber || $0 == "." }
            if let value = Double(digits), value > 0 {
                return value / 100
            }
        }

        return nil
    }
}

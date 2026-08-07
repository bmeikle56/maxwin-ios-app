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

enum PokerVariant: String, Codable, Sendable, CaseIterable {
    case nlh = "NLH"
    case plo = "PLO"

    /// Suffix used in stake strings like `2/5 NL` or `2/5 PLO`.
    var stakesSuffix: String {
        switch self {
        case .nlh: return "NL"
        case .plo: return "PLO"
        }
    }
}

enum PlayEnvironment: String, Codable, Sendable, CaseIterable {
    case online = "Online"
    case live = "Live"
}

struct PokerSession: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let date: Date
    let venue: String
    let gameType: GameType
    let pokerVariant: PokerVariant
    let stakes: String
    let durationMinutes: Int
    let buyIn: Double
    let cashOut: Double
    let hands: [Hand]

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

    init(
        id: UUID,
        date: Date,
        venue: String,
        gameType: GameType,
        pokerVariant: PokerVariant = .nlh,
        stakes: String,
        durationMinutes: Int,
        buyIn: Double,
        cashOut: Double,
        hands: [Hand]
    ) {
        self.id = id
        self.date = date
        self.venue = venue
        self.gameType = gameType
        self.pokerVariant = pokerVariant
        self.stakes = stakes
        self.durationMinutes = durationMinutes
        self.buyIn = buyIn
        self.cashOut = cashOut
        self.hands = hands
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, venue, gameType, pokerVariant, stakes
        case durationMinutes, buyIn, cashOut, hands
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        venue = try container.decode(String.self, forKey: .venue)
        gameType = try container.decode(GameType.self, forKey: .gameType)
        stakes = try container.decode(String.self, forKey: .stakes)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        buyIn = try container.decode(Double.self, forKey: .buyIn)
        cashOut = try container.decode(Double.self, forKey: .cashOut)
        hands = try container.decode([Hand].self, forKey: .hands)

        if let variant = try container.decodeIfPresent(PokerVariant.self, forKey: .pokerVariant) {
            pokerVariant = variant
        } else {
            pokerVariant = StakesParsing.pokerVariant(from: stakes)
        }
    }
}

enum StakesParsing {
    /// Extracts small and big blinds from cash stake text like `2/5 NL`. Returns nil for buy-in / unknown formats.
    static func smallAndBigBlind(from stakes: String) -> (small: Double, big: Double)? {
        let trimmed = stakes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let slash = trimmed.range(of: #"(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)"#, options: .regularExpression) {
            let match = String(trimmed[slash])
            let parts = match.split(whereSeparator: { $0 == "/" || $0.isWhitespace })
                .compactMap { Double($0) }
            if parts.count >= 2, parts[0] > 0, parts[1] > 0 {
                return (parts[0], parts[1])
            }
        }

        if let coded = trimmed.range(
            of: #"(\d+(?:\.\d+)?)\s*(NL|PLO)\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            let match = String(trimmed[coded])
            let digits = match.prefix { $0.isNumber || $0 == "." }
            if let value = Double(digits), value > 0 {
                let big = value / 100
                return (big / 2, big)
            }
        }

        return nil
    }

    /// Extracts the big blind from common stake strings like `2/5 NL`, `2/5 PLO`, or `25NL`.
    static func bigBlind(from stakes: String) -> Double? {
        smallAndBigBlind(from: stakes)?.big
    }

    /// Infers NLH vs PLO from stake text; defaults to NLH.
    static func pokerVariant(from stakes: String) -> PokerVariant {
        let trimmed = stakes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.range(of: #"\bPLO\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return .plo
        }
        return .nlh
    }

    /// Formats blinds as `1/2 NL` or `0.5/1 PLO`.
    static func format(smallBlind: Double, bigBlind: Double, variant: PokerVariant = .nlh) -> String {
        "\(formatBlind(smallBlind))/\(formatBlind(bigBlind)) \(variant.stakesSuffix)"
    }

    private static func formatBlind(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%g", value)
    }
}

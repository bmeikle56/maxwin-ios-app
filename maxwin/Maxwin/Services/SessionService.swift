//
//  SessionService.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

enum SessionServiceError: LocalizedError, Equatable {
    case notFound
    case invalidSession

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Session not found."
        case .invalidSession:
            return "Enter a venue and stakes to save this session."
        }
    }
}

protocol SessionServicing: AnyObject {
    func fetchSessions() async throws -> [PokerSession]
    func createSession(_ session: PokerSession) async throws -> PokerSession
    func updateSession(_ session: PokerSession) async throws -> PokerSession
    func deleteSession(id: UUID) async throws
}

@Observable
final class MockSessionService: SessionServicing {
    var networkDelayNanoseconds: UInt64 = 250_000_000

    private(set) var sessions: [PokerSession]

    init(sessions: [PokerSession] = MockSessionService.seedSessions) {
        self.sessions = sessions.sorted { $0.date > $1.date }
    }

    func fetchSessions() async throws -> [PokerSession] {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)
        return sessions
    }

    func createSession(_ session: PokerSession) async throws -> PokerSession {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)
        try validate(session)
        sessions.insert(session, at: 0)
        sessions.sort { $0.date > $1.date }
        return session
    }

    func updateSession(_ session: PokerSession) async throws -> PokerSession {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)
        try validate(session)
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            throw SessionServiceError.notFound
        }
        sessions[index] = session
        sessions.sort { $0.date > $1.date }
        return session
    }

    func deleteSession(id: UUID) async throws {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)
        guard sessions.contains(where: { $0.id == id }) else {
            throw SessionServiceError.notFound
        }
        sessions.removeAll { $0.id == id }
    }

    private func validate(_ session: PokerSession) throws {
        guard !session.venue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !session.stakes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SessionServiceError.invalidSession
        }
    }

    static let seedSessions: [PokerSession] = {
        let calendar = Calendar.current
        let now = Date()

        func date(daysAgo: Int, hour: Int = 19) -> Date {
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            let base = calendar.date(from: components) ?? now
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: base) ?? now
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        // Chronological arc (oldest → newest): early green → deep red → recovery → high green.
        // Cumulative roughly: +220 → +560 → +160 → −320 → −700 → −400 → +100 → +640 → +1440 → +2200
        return [
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 1),
                venue: "Bellagio",
                gameType: .cash,
                stakes: "2/5 NL",
                durationMinutes: 240,
                buyIn: 500,
                cashOut: 1260,
                hands: [
                    Hand(
                        id: UUID(),
                        handNumber: 1,
                        position: "BTN",
                        holeCards: "A♠ K♠",
                        result: 340,
                        notes: "Set over set on the turn",
                        detail: HandDetail(
                            board: "A♥ K♦ 7♣ 2♠ 9♥",
                            potSize: 780,
                            opponents: 1,
                            villainHand: "7♠ 7♦",
                            allInStreet: "Turn",
                            streets: [
                                StreetAction(id: UUID(), street: "Preflop", action: "Raise to $25, called", potAfter: 55),
                                StreetAction(id: UUID(), street: "Flop", action: "Bet $40, called", potAfter: 135),
                                StreetAction(id: UUID(), street: "Turn", action: "Villain shoves, snap call", potAfter: 780)
                            ]
                        )
                    ),
                    Hand(
                        id: UUID(),
                        handNumber: 2,
                        position: "CO",
                        holeCards: "Q♥ Q♦",
                        result: -85,
                        notes: "Folded to river jam",
                        detail: HandDetail(
                            board: "J♣ 8♦ 2♥ T♠ A♣",
                            potSize: 210,
                            opponents: 1,
                            villainHand: nil,
                            allInStreet: nil,
                            streets: [
                                StreetAction(id: UUID(), street: "River", action: "Faced jam, folded", potAfter: 210)
                            ]
                        )
                    ),
                    Hand(
                        id: UUID(),
                        handNumber: 3,
                        position: "SB",
                        holeCards: "J♣ T♣",
                        result: 210,
                        notes: "Flush vs top pair",
                        detail: nil
                    ),
                    Hand(
                        id: UUID(),
                        handNumber: 4,
                        position: "UTG",
                        holeCards: "A♦ Q♦",
                        result: -120,
                        notes: nil,
                        detail: nil
                    )
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 5),
                venue: "WSOP Satellite",
                gameType: .tournament,
                stakes: "$250 buy-in",
                durationMinutes: 410,
                buyIn: 250,
                cashOut: 1050,
                hands: [
                    Hand(
                        id: UUID(),
                        handNumber: 1,
                        position: "HJ",
                        holeCards: "A♠ K♦",
                        result: 620,
                        notes: "Final table double",
                        detail: HandDetail(
                            board: "A♣ 8♦ 4♠ K♥ 2♣",
                            potSize: 1_240,
                            opponents: 1,
                            villainHand: "A♥ Q♠",
                            allInStreet: "Flop",
                            streets: [
                                StreetAction(id: UUID(), street: "Flop", action: "Shove called", potAfter: 1_240)
                            ]
                        )
                    ),
                    Hand(id: UUID(), handNumber: 2, position: "SB", holeCards: "9♣ 9♦", result: 310, notes: nil, detail: nil)
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 12),
                venue: "ARIA",
                gameType: .cash,
                stakes: "1/3 NL",
                durationMinutes: 195,
                buyIn: 300,
                cashOut: 840,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "BB", holeCards: "7♥ 7♠", result: 180, notes: "Set mines pay off", detail: nil),
                    Hand(id: UUID(), handNumber: 2, position: "HJ", holeCards: "A♠ J♥", result: 95, notes: nil, detail: nil)
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 20),
                venue: "Online - Ignition",
                gameType: .cash,
                stakes: "25NL",
                durationMinutes: 110,
                buyIn: 100,
                cashOut: 600,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "CO", holeCards: "T♠ T♥", result: 88, notes: nil, detail: nil),
                    Hand(
                        id: UUID(),
                        handNumber: 2,
                        position: "BTN",
                        holeCards: "A♥ 5♥",
                        result: 58,
                        notes: "Rivered flush",
                        detail: HandDetail(
                            board: "K♥ 9♥ 2♣ 3♦ 7♥",
                            potSize: 92,
                            opponents: 2,
                            villainHand: nil,
                            allInStreet: nil,
                            streets: [
                                StreetAction(id: UUID(), street: "River", action: "Bet half pot, both fold", potAfter: 92)
                            ]
                        )
                    )
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 28, hour: 14),
                venue: "Local home game",
                gameType: .tournament,
                stakes: "$100 buy-in",
                durationMinutes: 280,
                buyIn: 100,
                cashOut: 400,
                hands: [
                    Hand(
                        id: UUID(),
                        handNumber: 1,
                        position: "MP",
                        holeCards: "K♥ K♦",
                        result: 220,
                        notes: "Laddered late",
                        detail: HandDetail(
                            board: "K♣ 9♠ 4♦ Q♥ 2♠",
                            potSize: 240,
                            opponents: 1,
                            villainHand: "A♦ Q♦",
                            allInStreet: "Turn",
                            streets: nil
                        )
                    ),
                    Hand(
                        id: UUID(),
                        handNumber: 2,
                        position: "BTN",
                        holeCards: "A♣ 9♣",
                        result: 45,
                        notes: "Chip up early",
                        detail: nil
                    )
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 42),
                venue: "Commerce",
                gameType: .cash,
                stakes: "5/10 NL",
                durationMinutes: 260,
                buyIn: 1500,
                cashOut: 1120,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "UTG", holeCards: "A♣ A♦", result: -420, notes: "Lost to rivered straight", detail: nil),
                    Hand(id: UUID(), handNumber: 2, position: "BTN", holeCards: "K♠ Q♠", result: -160, notes: nil, detail: nil)
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 55),
                venue: "The Bike",
                gameType: .cash,
                stakes: "2/5 NL",
                durationMinutes: 220,
                buyIn: 500,
                cashOut: 20,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "CO", holeCards: "J♠ J♥", result: -250, notes: "Coolered by kings", detail: nil),
                    Hand(id: UUID(), handNumber: 2, position: "BB", holeCards: "A♥ T♥", result: -180, notes: "Bluff caught", detail: nil)
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 70),
                venue: "Hustler",
                gameType: .cash,
                stakes: "1/3 NL",
                durationMinutes: 175,
                buyIn: 400,
                cashOut: 0,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "UTG", holeCards: "A♠ A♣", result: -280, notes: "Set over set", detail: nil),
                    Hand(id: UUID(), handNumber: 2, position: "BTN", holeCards: "K♦ Q♦", result: -95, notes: nil, detail: nil)
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 95),
                venue: "Venetian",
                gameType: .cash,
                stakes: "2/5 NL",
                durationMinutes: 200,
                buyIn: 500,
                cashOut: 840,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "HJ", holeCards: "A♣ K♣", result: 210, notes: nil, detail: nil),
                    Hand(id: UUID(), handNumber: 2, position: "SB", holeCards: "9♥ 9♦", result: 95, notes: "Stack off vs draw", detail: nil)
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 130),
                venue: "Online - PokerStars",
                gameType: .cash,
                stakes: "50NL",
                durationMinutes: 140,
                buyIn: 150,
                cashOut: 370,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "CO", holeCards: "A♠ Q♠", result: 120, notes: nil, detail: nil),
                    Hand(id: UUID(), handNumber: 2, position: "BTN", holeCards: "8♣ 8♦", result: 65, notes: "Set on wet board", detail: nil)
                ]
            )
        ]
        .sorted { $0.date > $1.date }
    }()

    /// Kept for previews / earnings seeding that still reference the old name.
    static var mockSessions: [PokerSession] { seedSessions }
}

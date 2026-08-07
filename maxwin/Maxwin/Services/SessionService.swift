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

struct SessionListPage: Equatable, Sendable {
    let sessions: [PokerSession]
    let offset: Int
    let limit: Int
    let totalCount: Int

    var hasMore: Bool {
        offset + sessions.count < totalCount
    }

    var nextOffset: Int {
        offset + sessions.count
    }
}

struct SessionListQuery: Equatable, Sendable {
    var offset: Int = 0
    var limit: Int = 5
    var searchText: String = ""
    var gameTypes: Set<GameType> = []
    var playEnvironments: Set<PlayEnvironment> = []
    var pokerVariants: Set<PokerVariant> = []
}

protocol SessionServicing: AnyObject {
    /// Paginated newest-first listing for the Sessions tab.
    func fetchSessionPage(_ query: SessionListQuery) async throws -> SessionListPage
    /// Full history for Track / earnings aggregates.
    func fetchAllSessions() async throws -> [PokerSession]
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

    func fetchSessionPage(_ query: SessionListQuery) async throws -> SessionListPage {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        let filtered = filteredSessions(
            searchText: query.searchText,
            gameTypes: query.gameTypes,
            playEnvironments: query.playEnvironments,
            pokerVariants: query.pokerVariants
        )
        let limit = max(query.limit, 1)
        let offset = max(query.offset, 0)
        let slice = Array(filtered.dropFirst(offset).prefix(limit))

        return SessionListPage(
            sessions: slice,
            offset: offset,
            limit: limit,
            totalCount: filtered.count
        )
    }

    func fetchAllSessions() async throws -> [PokerSession] {
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

    private func filteredSessions(
        searchText: String,
        gameTypes: Set<GameType>,
        playEnvironments: Set<PlayEnvironment>,
        pokerVariants: Set<PokerVariant>
    ) -> [PokerSession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return sessions.filter { session in
            if !gameTypes.isEmpty, !gameTypes.contains(session.gameType) {
                return false
            }
            if !playEnvironments.isEmpty, !playEnvironments.contains(session.playEnvironment) {
                return false
            }
            if !pokerVariants.isEmpty, !pokerVariants.contains(session.pokerVariant) {
                return false
            }

            guard !query.isEmpty else { return true }

            let haystacks: [String] = [
                session.venue,
                session.stakes,
                session.gameType.rawValue,
                session.playEnvironment.rawValue,
                session.pokerVariant.rawValue
            ] + session.hands.flatMap { hand in
                [hand.holeCards, hand.position, hand.notes ?? ""]
            }

            return haystacks.contains { $0.localizedCaseInsensitiveContains(query) }
        }
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
        let featured: [PokerSession] = [
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 1),
                venue: "Bellagio",
                gameType: .cash,
                stakes: "500NLH",
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
                stakes: "300NLH",
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
                date: date(daysAgo: 16),
                venue: "Commerce",
                gameType: .cash,
                pokerVariant: .plo,
                stakes: "1000PLO",
                durationMinutes: 210,
                buyIn: 2000,
                cashOut: 2680,
                hands: [
                    Hand(
                        id: UUID(),
                        handNumber: 1,
                        position: "BTN",
                        holeCards: "A♠ A♥ K♦ Q♣",
                        result: 420,
                        notes: "Double-suited aces hold",
                        detail: nil
                    ),
                    Hand(
                        id: UUID(),
                        handNumber: 2,
                        position: "CO",
                        holeCards: "J♥ T♥ 9♠ 8♠",
                        result: -180,
                        notes: nil,
                        detail: nil
                    )
                ]
            ),
            PokerSession(
                id: UUID(),
                date: date(daysAgo: 20),
                venue: "Ignition",
                gameType: .cash,
                playEnvironment: .online,
                stakes: "25NLH",
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
                date: date(daysAgo: 24),
                venue: "PokerStars",
                gameType: .cash,
                playEnvironment: .online,
                pokerVariant: .plo,
                stakes: "50PLO",
                durationMinutes: 95,
                buyIn: 200,
                cashOut: 140,
                hands: [
                    Hand(
                        id: UUID(),
                        handNumber: 1,
                        position: "MP",
                        holeCards: "A♦ K♦ J♣ T♣",
                        result: -60,
                        notes: nil,
                        detail: nil
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
                stakes: "1000NLH",
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
                stakes: "500NLH",
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
                stakes: "300NLH",
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
                stakes: "500NLH",
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
                venue: "PokerStars",
                gameType: .cash,
                playEnvironment: .online,
                stakes: "50NLH",
                durationMinutes: 140,
                buyIn: 150,
                cashOut: 370,
                hands: [
                    Hand(id: UUID(), handNumber: 1, position: "CO", holeCards: "A♠ Q♠", result: 120, notes: nil, detail: nil),
                    Hand(id: UUID(), handNumber: 2, position: "BTN", holeCards: "8♣ 8♦", result: 65, notes: "Set on wet board", detail: nil)
                ]
            )
        ]

        // Extra lightweight sessions so list pagination is easy to exercise in mocks.
        let venues = ["Bellagio", "ARIA", "Commerce", "The Bike", "Hustler", "Venetian", "Local home game", "Ignition"]
        let stakes = ["200NLH", "300NLH", "500NLH", "1000NLH", "25NLH", "50NLH", "500PLO", "1000PLO", "50PLO"]
        let extras: [PokerSession] = (0..<20).map { index in
            let buyIn = Double([200, 300, 500, 800][index % 4])
            let swing = Double([-180, -90, 40, 120, 260, -40][index % 6])
            let stake = index % 5 == 0 ? "$\(100 + index * 10) buy-in" : stakes[index % stakes.count]
            let venue = venues[index % venues.count]
            return PokerSession(
                id: UUID(),
                date: date(daysAgo: 140 + index * 3, hour: 18 + (index % 4)),
                venue: venue,
                gameType: index % 5 == 0 ? .tournament : .cash,
                playEnvironment: venue.localizedCaseInsensitiveContains("online") ? .online : .live,
                pokerVariant: StakesParsing.pokerVariant(from: stake),
                stakes: stake,
                durationMinutes: 90 + (index * 17) % 180,
                buyIn: buyIn,
                cashOut: buyIn + swing,
                hands: []
            )
        }

        return (featured + extras).sorted { $0.date > $1.date }
    }()

    /// Kept for previews / earnings seeding that still reference the old name.
    static var mockSessions: [PokerSession] { seedSessions }
}

//
//  TrackViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class TrackViewModel {
    var selectedRange: DateRangeFilter = .allTime
    var points: [EarningsDataPoint] = []
    var sessionsInRange: [PokerSession] = []
    var isLoading = false
    var errorMessage: String?

    private let earningsService: EarningsServicing
    private let sessionService: SessionServicing

    var totalProfit: Double {
        points.last?.cumulativeProfit ?? 0
    }

    /// Average big blinds won per 100 hands across cash sessions with parseable stakes.
    /// Uses session profit (not notable-hand results) and estimates hands from duration.
    var averageBBPer100: Double? {
        var totalBBWon = 0.0
        var totalHands = 0.0

        for session in sessionsInRange {
            guard session.gameType == .cash,
                  let bigBlind = session.bigBlind, bigBlind > 0,
                  session.durationMinutes > 0 else { continue }

            let hours = Double(session.durationMinutes) / 60.0
            let hands = hours * Self.estimatedHandsPerHour(for: session)
            guard hands > 0 else { continue }

            totalBBWon += session.profit / bigBlind
            totalHands += hands
        }

        guard totalHands > 0 else { return nil }
        return totalBBWon / totalHands * 100
    }

    /// Live slash stakes (~2/5) run slower than online NL (25NL).
    private static func estimatedHandsPerHour(for session: PokerSession) -> Double {
        let stakes = session.stakes
        if stakes.range(of: #"\d+(?:\.\d+)?\s*/\s*\d+(?:\.\d+)?"#, options: .regularExpression) != nil {
            return 30
        }
        return 60
    }

    var averageSessionMinutes: Int? {
        guard !sessionsInRange.isEmpty else { return nil }
        let total = sessionsInRange.reduce(0) { $0 + $1.durationMinutes }
        return Int((Double(total) / Double(sessionsInRange.count)).rounded())
    }

    /// Share of sessions that finished at or above break-even.
    /// Temporary mock for fire-aura testing — restore real calculation when done.
    var sessionWinRate: Double? {
        0.03
//        guard !sessionsInRange.isEmpty else { return nil }
//        let wins = sessionsInRange.filter { $0.profit >= 0 }.count
//        return Double(wins) / Double(sessionsInRange.count)
    }

    var animationsEnabled: Bool

    init(
        earningsService: EarningsServicing,
        sessionService: SessionServicing,
        animationsEnabled: Bool = true
    ) {
        self.earningsService = earningsService
        self.sessionService = sessionService
        self.animationsEnabled = animationsEnabled
    }

    func selectRange(_ range: DateRangeFilter) async {
        selectedRange = range
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        points = []
        sessionsInRange = []
        defer { isLoading = false }

        do {
            async let earnings = earningsService.fetchEarnings(for: selectedRange)
            async let sessions = sessionService.fetchSessions()

            points = try await earnings
            sessionsInRange = Self.filteredSessions(try await sessions, for: selectedRange)
        } catch {
            errorMessage = "Couldn't load winnings."
            points = []
            sessionsInRange = []
        }
    }

    private static func filteredSessions(
        _ sessions: [PokerSession],
        for range: DateRangeFilter
    ) -> [PokerSession] {
        let start = range.startDate()
        return sessions.filter { session in
            guard let start else { return true }
            return session.date >= start
        }
    }
}

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

    /// Average big blinds won per 100 hands, from logged hand results at parseable cash stakes.
    var averageBBPer100: Double? {
        var totalBBWon = 0.0
        var totalHands = 0

        for session in sessionsInRange {
            guard let bigBlind = session.bigBlind, bigBlind > 0 else { continue }
            for hand in session.hands {
                totalBBWon += hand.result / bigBlind
                totalHands += 1
            }
        }

        guard totalHands > 0 else { return nil }
        return totalBBWon / Double(totalHands) * 100
    }

    var averageSessionMinutes: Int? {
        guard !sessionsInRange.isEmpty else { return nil }
        let total = sessionsInRange.reduce(0) { $0 + $1.durationMinutes }
        return Int((Double(total) / Double(sessionsInRange.count)).rounded())
    }

    /// Share of sessions that finished at or above break-even.
    /// Temporary mock for fire-aura testing — restore real calculation when done.
    var sessionWinRate: Double? {
        0.98
//        guard !sessionsInRange.isEmpty else { return nil }
//        let wins = sessionsInRange.filter { $0.profit >= 0 }.count
//        return Double(wins) / Double(sessionsInRange.count)
    }

    var animationsEnabled: Bool
    var showYAxisLabels: Bool

    init(
        earningsService: EarningsServicing,
        sessionService: SessionServicing,
        animationsEnabled: Bool = true,
        showYAxisLabels: Bool = true
    ) {
        self.earningsService = earningsService
        self.sessionService = sessionService
        self.animationsEnabled = animationsEnabled
        self.showYAxisLabels = showYAxisLabels
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

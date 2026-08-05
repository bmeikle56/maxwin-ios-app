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

    private let trackDataService: TrackDataServicing

    var totalProfit: Double {
        points.last?.cumulativeProfit ?? 0
    }

    /// Total session time in the selected range, in minutes.
    var totalMinutesPlayed: Int {
        sessionsInRange.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Whole hours played in the selected range.
    var totalHoursPlayed: Int {
        Int((Double(totalMinutesPlayed) / 60.0).rounded())
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
        trackDataService: TrackDataServicing,
        animationsEnabled: Bool = true
    ) {
        self.trackDataService = trackDataService
        self.animationsEnabled = animationsEnabled
        // Apply cached data immediately when already warm (e.g. post-login prefetch).
        if let snapshot = trackDataService.snapshot(for: selectedRange) {
            apply(snapshot)
        }
    }

    func selectRange(_ range: DateRangeFilter) {
        selectedRange = range
        if let snapshot = trackDataService.snapshot(for: range) {
            apply(snapshot)
        } else {
            Task { await load() }
        }
    }

    /// Uses the prefetched cache when ready; otherwise waits on prefetch.
    func load() async {
        errorMessage = nil

        if trackDataService.isReady, let snapshot = trackDataService.snapshot(for: selectedRange) {
            apply(snapshot)
            return
        }

        isLoading = true
        defer { isLoading = false }

        await trackDataService.prefetch()

        if let snapshot = trackDataService.snapshot(for: selectedRange) {
            apply(snapshot)
        } else {
            errorMessage = "Couldn't load winnings."
            points = []
            sessionsInRange = []
        }
    }

    /// Re-applies the current range after the cache is refreshed (session CRUD).
    func reloadFromCache() {
        guard let snapshot = trackDataService.snapshot(for: selectedRange) else { return }
        apply(snapshot)
    }

    private func apply(_ snapshot: TrackRangeSnapshot) {
        points = snapshot.points
        sessionsInRange = snapshot.sessions
    }
}

//
//  TrackDataService.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/4/26.
//

import Foundation
import Observation

struct TrackRangeSnapshot: Equatable, Sendable {
    let points: [EarningsDataPoint]
    let sessions: [PokerSession]
}

protocol TrackDataServicing: AnyObject {
    var isReady: Bool { get }
    var isLoading: Bool { get }

    /// Fetches sessions once and precomputes earnings for every date range.
    func prefetch() async
    /// Forces a fresh fetch and rebuild (e.g. after session CRUD).
    func refresh() async
    func clear()
    func snapshot(for range: DateRangeFilter) -> TrackRangeSnapshot?
}

@Observable
final class MockTrackDataService: TrackDataServicing {
    private(set) var isReady = false
    private(set) var isLoading = false

    private let sessionService: SessionServicing
    private var snapshots: [DateRangeFilter: TrackRangeSnapshot] = [:]
    private var inFlight: Task<Void, Never>?

    init(sessionService: SessionServicing) {
        self.sessionService = sessionService
    }

    func prefetch() async {
        await load(force: false)
    }

    func refresh() async {
        await load(force: true)
    }

    func clear() {
        inFlight?.cancel()
        inFlight = nil
        snapshots = [:]
        isReady = false
        isLoading = false
    }

    func snapshot(for range: DateRangeFilter) -> TrackRangeSnapshot? {
        snapshots[range]
    }

    private func load(force: Bool) async {
        if let inFlight {
            await inFlight.value
            if !force || isReady { return }
        }

        if isReady && !force { return }

        let task = Task { @MainActor in
            self.isLoading = true
            defer { self.isLoading = false }

            do {
                let sessions = try await self.sessionService.fetchAllSessions()
                self.rebuild(from: sessions)
                self.isReady = true
            } catch {
                if !Task.isCancelled {
                    self.snapshots = [:]
                    self.isReady = false
                }
            }
        }

        inFlight = task
        await task.value
        if inFlight == task {
            inFlight = nil
        }
    }

    private func rebuild(from sessions: [PokerSession]) {
        var next: [DateRangeFilter: TrackRangeSnapshot] = [:]
        for range in DateRangeFilter.allCases {
            let filtered = Self.filteredSessions(sessions, for: range)
            next[range] = TrackRangeSnapshot(
                points: Self.earningsPoints(from: filtered),
                sessions: filtered
            )
        }
        snapshots = next
    }

    private static func filteredSessions(
        _ sessions: [PokerSession],
        for range: DateRangeFilter
    ) -> [PokerSession] {
        let start = range.startDate()
        let filtered = sessions.filter { session in
            guard let start else { return true }
            return session.date >= start
        }
        return filtered.sorted { $0.date < $1.date }
    }

    private static func earningsPoints(from sessions: [PokerSession]) -> [EarningsDataPoint] {
        var running: Double = 0
        return sessions.map { session in
            running += session.profit
            return EarningsDataPoint(
                id: session.id,
                date: session.date,
                cumulativeProfit: running,
                periodProfit: session.profit
            )
        }
    }
}

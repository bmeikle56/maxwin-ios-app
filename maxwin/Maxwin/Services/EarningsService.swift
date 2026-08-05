//
//  EarningsService.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

protocol EarningsServicing: AnyObject {
    func fetchEarnings(for range: DateRangeFilter) async throws -> [EarningsDataPoint]
}

@Observable
final class MockEarningsService: EarningsServicing {
    var networkDelayNanoseconds: UInt64 = 250_000_000

    private let sessionService: SessionServicing

    init(sessionService: SessionServicing) {
        self.sessionService = sessionService
    }

    func fetchEarnings(for range: DateRangeFilter) async throws -> [EarningsDataPoint] {
        try await Task.sleep(nanoseconds: networkDelayNanoseconds)

        let sessions = try await sessionService.fetchAllSessions()
            .sorted { $0.date < $1.date }

        let start = range.startDate()
        let filtered = sessions.filter { session in
            guard let start else { return true }
            return session.date >= start
        }

        var running: Double = 0
        return filtered.map { session in
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

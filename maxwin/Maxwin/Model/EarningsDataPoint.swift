//
//  EarningsDataPoint.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

struct EarningsDataPoint: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let date: Date
    /// Running bankroll delta relative to the start of the selected range.
    let cumulativeProfit: Double
    /// Profit/loss for that individual day or session marker.
    let periodProfit: Double
}

enum DateRangeFilter: String, CaseIterable, Identifiable, Sendable {
    case allTime = "All time"
    case lastYear = "Last year"
    case lastMonth = "Last month"
    case lastWeek = "Last week"

    var id: String { rawValue }

    func startDate(relativeTo now: Date = .now, calendar: Calendar = .current) -> Date? {
        switch self {
        case .allTime:
            return nil
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: now)
        case .lastWeek:
            return calendar.date(byAdding: .day, value: -7, to: now)
        }
    }
}

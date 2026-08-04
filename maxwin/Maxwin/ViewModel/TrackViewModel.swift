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
    var isLoading = false
    var errorMessage: String?

    private let earningsService: EarningsServicing

    var totalProfit: Double {
        points.last?.cumulativeProfit ?? 0
    }

    var animationsEnabled: Bool
    var showYAxisLabels: Bool

    init(
        earningsService: EarningsServicing,
        animationsEnabled: Bool = true,
        showYAxisLabels: Bool = true
    ) {
        self.earningsService = earningsService
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
        defer { isLoading = false }

        do {
            points = try await earningsService.fetchEarnings(for: selectedRange)
        } catch {
            errorMessage = "Couldn't load winnings."
            points = []
        }
    }
}

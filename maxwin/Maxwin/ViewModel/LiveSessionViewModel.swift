//
//  LiveSessionViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/4/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class LiveSessionViewModel {
    private var runningStartedAt: Date
    /// Elapsed time accumulated across completed run segments (excludes current run).
    private var accumulatedElapsed: TimeInterval = 0
    private(set) var isPaused = false

    var handsPlayed = 0
    private(set) var loggedHands: [HandDraft] = []

    /// Current hand being tracked one at a time.
    var position = ""
    var holeCards = ""
    var result: Double?
    var notes = ""

    init(startedAt: Date = .now) {
        self.runningStartedAt = startedAt
    }

    var hasProgress: Bool {
        handsPlayed > 0
            || !loggedHands.isEmpty
            || hasCurrentHandInput
            || accumulatedElapsed > 0
            || !isPaused && Date.now.timeIntervalSince(runningStartedAt) > 0
    }

    var hasCurrentHandInput: Bool {
        !position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !holeCards.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || result != nil
            || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    func pause() {
        guard !isPaused else { return }
        accumulatedElapsed += Date.now.timeIntervalSince(runningStartedAt)
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        runningStartedAt = .now
        isPaused = false
    }

    func elapsed(at date: Date = .now) -> TimeInterval {
        if isPaused {
            return max(0, accumulatedElapsed)
        }
        return max(0, accumulatedElapsed + date.timeIntervalSince(runningStartedAt))
    }

    func formattedElapsed(at date: Date = .now) -> String {
        let total = Int(elapsed(at: date).rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Bumps hands played and, when the current hand has input, logs it then clears the form.
    func incrementHandsPlayed() {
        guard !isPaused else { return }

        handsPlayed += 1

        if hasCurrentHandInput {
            var hand = HandDraft.blank(handNumber: handsPlayed)
            hand.position = position.trimmingCharacters(in: .whitespacesAndNewlines)
            if hand.position.isEmpty { hand.position = "—" }
            hand.holeCards = holeCards.trimmingCharacters(in: .whitespacesAndNewlines)
            hand.result = result ?? 0
            hand.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            loggedHands.append(hand)
            clearCurrentHand()
        }
    }

    func clearCurrentHand() {
        position = ""
        holeCards = ""
        result = nil
        notes = ""
    }
}

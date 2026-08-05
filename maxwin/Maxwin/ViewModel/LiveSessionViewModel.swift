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

    /// Stakes for converting hand results into big blinds.
    var smallBlind: Double?
    var bigBlind: Double?
    /// Running total of big blinds won/lost from logged hand results.
    private(set) var bbWon: Double = 0

    /// Current hand being tracked one at a time.
    var position: PokerPosition?
    var holeCard1 = ""
    var holeCard2 = ""
    var result: Double?
    var notes = ""

    var isSaving = false
    var errorMessage: String?

    init(startedAt: Date = .now) {
        self.runningStartedAt = startedAt
    }

    var hasProgress: Bool {
        handsPlayed > 0
            || !loggedHands.isEmpty
            || hasCurrentHandInput
            || smallBlind != nil
            || bigBlind != nil
            || bbWon != 0
            || accumulatedElapsed > 0
            || !isPaused && Date.now.timeIntervalSince(runningStartedAt) > 0
    }

    /// Signed BB total for the session, e.g. `+20BB` or `-4.5BB`.
    var formattedBBWon: String {
        let value: String
        if bbWon == bbWon.rounded() {
            value = String(format: "%.0f", bbWon)
        } else {
            value = String(format: "%.1f", bbWon)
        }
        let sign = bbWon > 0 ? "+" : ""
        return "\(sign)\(value)BB"
    }

    var hasCurrentHandInput: Bool {
        position != nil
            || !holeCard1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !holeCard2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || result != nil
            || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var combinedHoleCards: String {
        [holeCard1, holeCard2]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var canSave: Bool {
        guard isPaused else { return false }
        guard let smallBlind, smallBlind > 0,
              let bigBlind, bigBlind > 0 else { return false }
        return true
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

    /// Bumps hands played; saves current hand detail when present, then always clears the form.
    func incrementHandsPlayed() {
        guard !isPaused else { return }
        commitHand()
    }

    /// Builds a `PokerSession` from the live recording. Commits any in-progress hand first.
    func makeSession() -> PokerSession? {
        errorMessage = nil
        pause()
        commitPendingHandIfNeeded()

        guard let smallBlind, smallBlind > 0,
              let bigBlind, bigBlind > 0 else {
            errorMessage = "Enter small blind and big blind."
            return nil
        }

        let profit = bbWon * bigBlind
        let durationMinutes = max(Int((elapsed() / 60.0).rounded()), handsPlayed > 0 ? 1 : 0)

        return PokerSession(
            id: UUID(),
            date: .now,
            venue: "Live Session",
            gameType: .cash,
            stakes: StakesParsing.format(smallBlind: smallBlind, bigBlind: bigBlind),
            durationMinutes: durationMinutes,
            buyIn: 0,
            cashOut: profit,
            hands: loggedHands.enumerated().map { index, draft in
                draft.makeHand(fallbackNumber: index + 1)
            }
        )
    }

    private func commitPendingHandIfNeeded() {
        guard hasCurrentHandInput || result != nil else { return }
        commitHand()
    }

    private func commitHand() {
        handsPlayed += 1

        if let result, let bigBlind, bigBlind > 0 {
            bbWon += result / bigBlind
        }

        if hasCurrentHandInput {
            var hand = HandDraft.blank(handNumber: handsPlayed)
            hand.position = position?.rawValue ?? "—"
            hand.holeCards = combinedHoleCards
            hand.result = result ?? 0
            hand.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            loggedHands.append(hand)
        }

        clearCurrentHand()
    }

    func clearCurrentHand() {
        position = nil
        holeCard1 = ""
        holeCard2 = ""
        result = nil
        notes = ""
    }
}

//
//  SessionEditorViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class SessionEditorViewModel {
    var draft: SessionDraft
    var isSaving = false
    var errorMessage: String?
    var expandedHandDraftIDs: Set<UUID> = []

    var title: String {
        draft.isEditing ? "Edit Session" : "New Session"
    }

    private let sessionService: SessionServicing

    init(draft: SessionDraft, sessionService: SessionServicing) {
        self.draft = draft
        self.sessionService = sessionService
    }

    func addHand() {
        let number = (draft.hands.map(\.handNumber).max() ?? 0) + 1
        let hand = HandDraft.blank(handNumber: number)
        draft.hands.append(hand)
        expandedHandDraftIDs.insert(hand.id)
    }

    func removeHand(_ handID: UUID) {
        draft.hands.removeAll { $0.id == handID }
        expandedHandDraftIDs.remove(handID)
        renumberHands()
    }

    func toggleHandExpanded(_ handID: UUID) {
        if expandedHandDraftIDs.contains(handID) {
            expandedHandDraftIDs.remove(handID)
        } else {
            expandedHandDraftIDs.insert(handID)
        }
    }

    func isHandExpanded(_ handID: UUID) -> Bool {
        expandedHandDraftIDs.contains(handID)
    }

    /// Persists the draft. Hand `detail` is only sent when `includeDetail` is on and has content.
    @discardableResult
    func save() async -> Bool {
        errorMessage = nil

        guard let buyIn = draft.buyIn, let cashOut = draft.cashOut else {
            errorMessage = "Enter a buy-in and cash-out."
            return false
        }

        guard let smallBlind = draft.smallBlind, let bigBlind = draft.bigBlind else {
            errorMessage = "Enter small blind and big blind."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let session = draft.makeSession(
            buyIn: buyIn,
            cashOut: cashOut,
            smallBlind: smallBlind,
            bigBlind: bigBlind
        )

        do {
            if draft.isEditing {
                _ = try await sessionService.updateSession(session)
            } else {
                _ = try await sessionService.createSession(session)
            }
            return true
        } catch let error as SessionServiceError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = "Couldn't save session. Try again."
            return false
        }
    }

    private func renumberHands() {
        for index in draft.hands.indices {
            draft.hands[index].handNumber = index + 1
        }
    }
}

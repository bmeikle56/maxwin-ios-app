//
//  SessionsViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class SessionsViewModel {
    var sessions: [PokerSession] = []
    var expandedSessionIDs: Set<UUID> = []
    var expandedHandIDs: Set<UUID> = []
    var isLoading = false
    var isMutating = false
    var errorMessage: String?
    var sessionPendingDelete: PokerSession?
    var editorViewModel: SessionEditorViewModel?

    private let sessionService: SessionServicing

    init(sessionService: SessionServicing) {
        self.sessionService = sessionService
    }

    var isEditorPresented: Bool {
        get { editorViewModel != nil }
        set {
            if !newValue {
                editorViewModel = nil
            }
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            sessions = try await sessionService.fetchSessions()
        } catch {
            errorMessage = "Couldn't load sessions. Pull to try again."
        }
    }

    func beginCreateSession() {
        editorViewModel = SessionEditorViewModel(
            draft: .blank(),
            sessionService: sessionService
        )
    }

    func beginEditSession(_ session: PokerSession) {
        editorViewModel = SessionEditorViewModel(
            draft: SessionDraft(session: session),
            sessionService: sessionService
        )
    }

    func handleEditorSaved() async {
        editorViewModel = nil
        await load()
    }

    func requestDelete(_ session: PokerSession) {
        sessionPendingDelete = session
    }

    func confirmDelete() async {
        guard let session = sessionPendingDelete else { return }
        sessionPendingDelete = nil
        isMutating = true
        defer { isMutating = false }

        do {
            try await sessionService.deleteSession(id: session.id)
            sessions.removeAll { $0.id == session.id }
            expandedSessionIDs.remove(session.id)
            for hand in session.hands {
                expandedHandIDs.remove(hand.id)
            }
        } catch {
            errorMessage = "Couldn't delete session. Try again."
        }
    }

    func toggleSessionExpanded(_ sessionID: UUID) {
        if expandedSessionIDs.contains(sessionID) {
            expandedSessionIDs.remove(sessionID)
        } else {
            expandedSessionIDs.insert(sessionID)
        }
    }

    func isSessionExpanded(_ sessionID: UUID) -> Bool {
        expandedSessionIDs.contains(sessionID)
    }

    func toggleHandExpanded(_ handID: UUID) {
        if expandedHandIDs.contains(handID) {
            expandedHandIDs.remove(handID)
        } else {
            expandedHandIDs.insert(handID)
        }
    }

    func isHandExpanded(_ handID: UUID) -> Bool {
        expandedHandIDs.contains(handID)
    }

    /// Hand detail is optional at the model/service layer; only present when non-nil.
    func detail(for hand: Hand) -> HandDetail? {
        hand.detail
    }
}

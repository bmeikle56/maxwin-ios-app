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
        } catch {
            errorMessage = "Couldn't delete session. Try again."
        }
    }
}

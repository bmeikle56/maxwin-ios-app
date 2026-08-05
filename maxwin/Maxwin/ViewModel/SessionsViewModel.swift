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
    var searchText = ""
    var showFavoritesOnly = false
    var isLoading = false
    var isMutating = false
    var errorMessage: String?
    var sessionPendingDelete: PokerSession?
    var editorViewModel: SessionEditorViewModel?
    var liveSessionViewModel: LiveSessionViewModel?

    private let sessionService: SessionServicing
    private let trackDataService: TrackDataServicing
    var onTrackDataChanged: (() -> Void)?

    init(
        sessionService: SessionServicing,
        trackDataService: TrackDataServicing
    ) {
        self.sessionService = sessionService
        self.trackDataService = trackDataService
    }

    var isEditorPresented: Bool {
        get { editorViewModel != nil }
        set {
            if !newValue {
                editorViewModel = nil
            }
        }
    }

    var isLiveSessionPresented: Bool {
        get { liveSessionViewModel != nil }
        set {
            if !newValue {
                liveSessionViewModel = nil
            }
        }
    }

    var filteredSessions: [PokerSession] {
        sessions.filter { session in
            if showFavoritesOnly && !session.isFavorite {
                return false
            }
            return matchesSearch(session)
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

    func beginLiveSession() {
        liveSessionViewModel = LiveSessionViewModel()
    }

    func discardLiveSession() {
        liveSessionViewModel = nil
    }

    /// Persists the live recording as a new session, then dismisses the live sheet.
    func saveLiveSession() async {
        guard let liveSessionViewModel else { return }

        liveSessionViewModel.isSaving = true
        defer { liveSessionViewModel.isSaving = false }

        guard let session = liveSessionViewModel.makeSession() else { return }

        isMutating = true
        defer { isMutating = false }

        do {
            _ = try await sessionService.createSession(session)
            self.liveSessionViewModel = nil
            await load()
            await refreshTrackCache()
        } catch let error as SessionServiceError {
            liveSessionViewModel.errorMessage = error.localizedDescription
        } catch {
            liveSessionViewModel.errorMessage = "Couldn't save session. Try again."
        }
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
        await refreshTrackCache()
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
            await refreshTrackCache()
        } catch {
            errorMessage = "Couldn't delete session. Try again."
        }
    }

    func toggleSessionFavorite(_ session: PokerSession) async {
        var updated = session
        updated.isFavorite.toggle()
        await persistSession(updated)
    }

    private func persistSession(_ session: PokerSession) async {
        isMutating = true
        defer { isMutating = false }

        do {
            let saved = try await sessionService.updateSession(session)
            if let index = sessions.firstIndex(where: { $0.id == saved.id }) {
                sessions[index] = saved
            }
        } catch {
            errorMessage = "Couldn't update favorite. Try again."
        }
    }

    private func refreshTrackCache() async {
        await trackDataService.refresh()
        onTrackDataChanged?()
    }

    private func matchesSearch(_ session: PokerSession) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let haystacks: [String] = [
            session.venue,
            session.stakes,
            session.gameType.rawValue
        ] + session.hands.flatMap { hand in
            [hand.holeCards, hand.position, hand.notes ?? ""]
        }

        return haystacks.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

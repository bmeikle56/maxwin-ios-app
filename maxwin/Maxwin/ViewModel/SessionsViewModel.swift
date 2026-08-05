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
    var isLoadingMore = false
    var isMutating = false
    var errorMessage: String?
    var sessionPendingDelete: PokerSession?
    var editorViewModel: SessionEditorViewModel?
    var liveSessionViewModel: LiveSessionViewModel?

    private(set) var hasMore = false
    private var nextOffset = 0
    private let pageSize = 10

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

    func load() async {
        await reload(reset: true)
    }

    func loadMoreIfNeeded(currentSessionID: UUID) async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        guard sessions.last?.id == currentSessionID else { return }
        await reload(reset: false)
    }

    func setShowFavoritesOnly(_ value: Bool) {
        guard showFavoritesOnly != value else { return }
        showFavoritesOnly = value
        sessions = []
        hasMore = false
        nextOffset = 0
        Task { await reload(reset: true) }
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
            await reload(reset: true)
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
        await reload(reset: true)
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

    private func reload(reset: Bool) async {
        if reset {
            guard !isLoading else { return }
            isLoading = true
            errorMessage = nil
        } else {
            guard !isLoadingMore, hasMore else { return }
            isLoadingMore = true
        }
        defer {
            if reset {
                isLoading = false
            } else {
                isLoadingMore = false
            }
        }

        let offset = reset ? 0 : nextOffset
        let query = SessionListQuery(
            offset: offset,
            limit: pageSize,
            favoritesOnly: showFavoritesOnly,
            searchText: searchText
        )

        do {
            let page = try await sessionService.fetchSessionPage(query)
            if reset {
                sessions = page.sessions
            } else {
                let existingIDs = Set(sessions.map(\.id))
                sessions.append(contentsOf: page.sessions.filter { !existingIDs.contains($0.id) })
            }
            nextOffset = page.nextOffset
            hasMore = page.hasMore
        } catch {
            if reset && sessions.isEmpty {
                errorMessage = "Couldn't load sessions. Pull to try again."
            } else {
                errorMessage = "Couldn't load more sessions."
            }
        }
    }

    private func persistSession(_ session: PokerSession) async {
        isMutating = true
        defer { isMutating = false }

        do {
            let saved = try await sessionService.updateSession(session)
            if let index = sessions.firstIndex(where: { $0.id == saved.id }) {
                if showFavoritesOnly && !saved.isFavorite {
                    sessions.remove(at: index)
                } else {
                    sessions[index] = saved
                }
            }
        } catch {
            errorMessage = "Couldn't update favorite. Try again."
        }
    }

    private func refreshTrackCache() async {
        await trackDataService.refresh()
        onTrackDataChanged?()
    }
}

//
//  SessionsViewModel.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation
import Observation

struct SessionWeekGroup: Identifiable, Equatable {
    var id: Date { weekStart }
    let weekStart: Date
    let sessions: [PokerSession]

    var title: String {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startText = formatter.string(from: weekStart)
        let endText = formatter.string(from: end)

        if calendar.component(.year, from: weekStart) == calendar.component(.year, from: Date()) {
            return "\(startText) – \(endText)"
        }

        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: end))"
    }
}

enum SessionFilterChip: String, CaseIterable, Identifiable, Hashable {
    case cash
    case tournament
    case live
    case online
    case nlh
    case plo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "Cash"
        case .tournament: return "Tournament"
        case .live: return "Live"
        case .online: return "Online"
        case .nlh: return "NLH"
        case .plo: return "PLO"
        }
    }

    /// Cream chips for Online / Tournament / PLO; felt green for Live / Cash / NLH.
    var usesCreamStyle: Bool {
        switch self {
        case .online, .tournament, .plo: return true
        case .live, .cash, .nlh: return false
        }
    }
}

@Observable
@MainActor
final class SessionsViewModel {
    var sessions: [PokerSession] = []
    var searchText = ""
    var activeFilters: Set<SessionFilterChip> = []
    var condensedListEnabled: Bool
    var isLoading = false
    var isLoadingMore = false
    var isMutating = false
    var errorMessage: String?
    var sessionPendingDelete: PokerSession?
    var editorViewModel: SessionEditorViewModel?
    var liveSessionViewModel: LiveSessionViewModel?

    private(set) var hasMore = false
    private var nextOffset = 0
    /// Small page so the first load roughly fills one screen; more load on scroll.
    private let pageSize = 5

    private let sessionService: SessionServicing
    private let trackDataService: TrackDataServicing
    var onTrackDataChanged: (() -> Void)?

    init(
        sessionService: SessionServicing,
        trackDataService: TrackDataServicing,
        condensedListEnabled: Bool = false
    ) {
        self.sessionService = sessionService
        self.trackDataService = trackDataService
        self.condensedListEnabled = condensedListEnabled
    }

    var hasActiveFilters: Bool {
        !activeFilters.isEmpty
    }

    var sessionsByWeek: [SessionWeekGroup] {
        let calendar = Calendar.current
        var groups: [Date: [PokerSession]] = [:]
        var order: [Date] = []

        for session in sessions {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.date)?.start
                ?? calendar.startOfDay(for: session.date)
            if groups[weekStart] == nil {
                order.append(weekStart)
                groups[weekStart] = []
            }
            groups[weekStart, default: []].append(session)
        }

        return order.map { weekStart in
            SessionWeekGroup(weekStart: weekStart, sessions: groups[weekStart] ?? [])
        }
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
        guard let index = sessions.firstIndex(where: { $0.id == currentSessionID }) else { return }
        // Prefetch when one of the last two visible rows appears.
        guard index >= sessions.count - 2 else { return }
        await reload(reset: false)
    }

    func toggleFilter(_ chip: SessionFilterChip) {
        if activeFilters.contains(chip) {
            activeFilters.remove(chip)
        } else {
            activeFilters.insert(chip)
        }
        sessions = []
        hasMore = false
        nextOffset = 0
        Task { await reload(reset: true) }
    }

    func clearFilters() {
        guard !activeFilters.isEmpty else { return }
        activeFilters = []
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
            searchText: searchText,
            gameTypes: selectedGameTypes,
            playEnvironments: selectedPlayEnvironments,
            pokerVariants: selectedPokerVariants
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

    private var selectedGameTypes: Set<GameType> {
        var types: Set<GameType> = []
        if activeFilters.contains(.cash) { types.insert(.cash) }
        if activeFilters.contains(.tournament) { types.insert(.tournament) }
        return types
    }

    private var selectedPlayEnvironments: Set<PlayEnvironment> {
        var environments: Set<PlayEnvironment> = []
        if activeFilters.contains(.live) { environments.insert(.live) }
        if activeFilters.contains(.online) { environments.insert(.online) }
        return environments
    }

    private var selectedPokerVariants: Set<PokerVariant> {
        var variants: Set<PokerVariant> = []
        if activeFilters.contains(.nlh) { variants.insert(.nlh) }
        if activeFilters.contains(.plo) { variants.insert(.plo) }
        return variants
    }

    private func refreshTrackCache() async {
        await trackDataService.refresh()
        onTrackDataChanged?()
    }
}

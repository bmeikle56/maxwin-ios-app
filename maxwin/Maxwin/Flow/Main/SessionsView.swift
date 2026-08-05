//
//  SessionsView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct SessionsView: View {
    @Bindable var viewModel: SessionsViewModel

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView()
                        .tint(MaxwinTheme.gold)
                } else if let errorMessage = viewModel.errorMessage, viewModel.sessions.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .feltScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.setShowFavoritesOnly(!viewModel.showFavoritesOnly)
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.cream)
                    }
                    .accessibilityLabel(viewModel.showFavoritesOnly ? "Show all sessions" : "Show favorites only")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.beginLiveSession()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.cream)
                    }
                    .accessibilityLabel("Start live session")

                    Button {
                        viewModel.beginCreateSession()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.cream)
                    }
                    .accessibilityLabel("Add session")
                }
            }
            .navigationDestination(for: UUID.self) { sessionID in
                SessionDetailView(viewModel: viewModel, sessionID: sessionID)
            }
            .task {
                if viewModel.sessions.isEmpty {
                    await viewModel.load()
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .confirmationDialog(
                "Delete session?",
                isPresented: Binding(
                    get: { viewModel.sessionPendingDelete != nil },
                    set: { if !$0 { viewModel.sessionPendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.confirmDelete() }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.sessionPendingDelete = nil
                }
            } message: {
                if let session = viewModel.sessionPendingDelete {
                    Text("Remove \(session.venue) on \(dateFormatter.string(from: session.date))? This can't be undone.")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.showFavoritesOnly ? "star" : "suit.spade.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(MaxwinTheme.gold)
            Text(viewModel.showFavoritesOnly ? "No favorites yet" : "No sessions yet")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(MaxwinTheme.cream)
            Text(
                viewModel.showFavoritesOnly
                ? "Star a session to pin it here."
                : "Log your first cash game or tournament."
            )
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(MaxwinTheme.mutedCream)
            .multilineTextAlignment(.center)

            if viewModel.showFavoritesOnly {
                Button {
                    viewModel.setShowFavoritesOnly(false)
                } label: {
                    Text("Show all sessions")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.feltDeep)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(MaxwinTheme.gold, in: Capsule())
                }
                .padding(.top, 4)
            } else {
                Button {
                    viewModel.beginCreateSession()
                } label: {
                    Text("Add Session")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.feltDeep)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(MaxwinTheme.gold, in: Capsule())
                }
                .padding(.top, 4)
            }
        }
        .padding()
    }

    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.lossRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(viewModel.sessions) { session in
                    NavigationLink(value: session.id) {
                        sessionCard(session)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(currentSessionID: session.id)
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(MaxwinTheme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func sessionCard(_ session: PokerSession) -> some View {
        // let glow = session.profit >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed

        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.venue)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)

                Text("\(session.gameType.rawValue) · \(session.stakes)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)

                Text("\(dateFormatter.string(from: session.date)) · \(session.formattedDuration)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream.opacity(0.85))
            }

            Spacer(minLength: 8)

            SessionProfitText(profit: session.profit)
        }
        .padding(16)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    session.isFavorite ? MaxwinTheme.gold.opacity(0.45) : MaxwinTheme.fieldStroke,
                    lineWidth: 1
                )
        }
        // Glow temporarily disabled.
        // .background {
        //     RoundedRectangle(cornerRadius: 16, style: .continuous)
        //         .fill(glow.opacity(0.14))
        //         .blur(radius: 5)
        //         .padding(1)
        // }
        // .shadow(color: glow.opacity(0.16), radius: 4, x: 0, y: 0)
    }
}

#Preview {
    SessionsView(
        viewModel: SessionsViewModel(
            sessionService: MockSessionService(),
            trackDataService: MockTrackDataService(sessionService: MockSessionService())
        )
    )
}

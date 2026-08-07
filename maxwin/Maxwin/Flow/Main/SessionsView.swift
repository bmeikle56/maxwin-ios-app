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

    private let condensedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                Group {
                    if viewModel.isLoading && viewModel.sessions.isEmpty {
                        ProgressView()
                            .tint(MaxwinTheme.gold)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.sessions.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(MaxwinTheme.mutedCream)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.sessions.isEmpty {
                        emptyState
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        sessionsList
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .feltScreenBackground()
            .navigationTitle("Sessions")
            .toolbar {
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

    private var filterBar: some View {
        FlowLayout(spacing: 8, rowSpacing: 8) {
            ForEach(SessionFilterChip.allCases) { chip in
                filterChip(chip)
            }

            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(_ chip: SessionFilterChip) -> some View {
        let isSelected = viewModel.activeFilters.contains(chip)

        return Button {
            viewModel.toggleFilter(chip)
        } label: {
            Text(chip.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(filterChipForeground(chip: chip, isSelected: isSelected))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    filterChipBackground(chip: chip, isSelected: isSelected),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected
                            ? Color.clear
                            : MaxwinTheme.fieldStroke,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }

    private func filterChipForeground(chip: SessionFilterChip, isSelected: Bool) -> Color {
        guard isSelected else { return MaxwinTheme.mutedCream }
        return chip.usesCreamStyle ? MaxwinTheme.feltDeep : MaxwinTheme.cream
    }

    private func filterChipBackground(chip: SessionFilterChip, isSelected: Bool) -> Color {
        guard isSelected else { return MaxwinTheme.fieldFill }
        return chip.usesCreamStyle ? MaxwinTheme.cream : MaxwinTheme.badgeGreen
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "suit.spade.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(MaxwinTheme.gold)
            Text(viewModel.hasActiveFilters ? "No matching sessions" : "No sessions yet")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(MaxwinTheme.cream)
            Text(
                viewModel.hasActiveFilters
                ? "Try clearing or changing filters."
                : "Log your first cash game or tournament."
            )
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(MaxwinTheme.mutedCream)
            .multilineTextAlignment(.center)

            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear Filters")
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
            LazyVStack(spacing: viewModel.condensedListEnabled ? 0 : 12) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.lossRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, viewModel.condensedListEnabled ? 8 : 0)
                }

                if viewModel.condensedListEnabled {
                    condensedSessionsList
                } else {
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
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(MaxwinTheme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private var condensedSessionsList: some View {
        let weeks = viewModel.sessionsByWeek

        return ForEach(Array(weeks.enumerated()), id: \.element.id) { index, week in
            VStack(alignment: .leading, spacing: 0) {
                Text(week.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
                    .padding(.top, index == 0 ? 0 : 4)

                VStack(spacing: 0) {
                    ForEach(week.sessions) { session in
                        NavigationLink(value: session.id) {
                            condensedSessionRow(session)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentSessionID: session.id)
                            }
                        }

                        if session.id != week.sessions.last?.id {
                            Divider()
                                .background(MaxwinTheme.fieldStroke)
                                .padding(.leading, 12)
                        }
                    }
                }
                .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
                }

                if index < weeks.count - 1 {
                    Divider()
                        .background(MaxwinTheme.divider)
                        .padding(.vertical, 12)
                }
            }
        }
    }

    private func condensedSessionRow(_ session: PokerSession) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                sessionBadges(session, compact: true)

                venueAndStakes(session, fontSize: 14, weight: .semibold)
                    .lineLimit(1)

                Text(condensedDateFormatter.string(from: session.date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            SessionProfitText(profit: session.profit, fontSize: 14)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func sessionCard(_ session: PokerSession) -> some View {
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                sessionBadges(session, compact: false)

                venueAndStakes(session, fontSize: 17, weight: .semibold)

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
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func sessionBadges(_ session: PokerSession, compact: Bool) -> some View {
        HStack(spacing: compact ? 4 : 6) {
            sessionBadge(
                session.playEnvironment.rawValue,
                compact: compact,
                usesCreamStyle: session.playEnvironment == .online
            )
            sessionBadge(
                session.gameType.rawValue,
                compact: compact,
                usesCreamStyle: session.gameType == .tournament
            )
            sessionBadge(
                session.pokerVariant.rawValue,
                compact: compact,
                usesCreamStyle: session.pokerVariant == .plo
            )
        }
    }

    private func venueAndStakes(
        _ session: PokerSession,
        fontSize: CGFloat,
        weight: Font.Weight
    ) -> some View {
        HStack(spacing: 6) {
            Text(session.venue)
                .foregroundStyle(MaxwinTheme.cream)

            Text("·")
                .foregroundStyle(MaxwinTheme.mutedCream)

            Text(session.stakes)
                .foregroundStyle(MaxwinTheme.cream)
        }
        .font(.system(size: fontSize, weight: weight, design: .rounded))
    }

    private func sessionBadge(
        _ title: String,
        compact: Bool,
        usesCreamStyle: Bool
    ) -> some View {
        Text(title)
            .font(.system(size: compact ? 9 : 10, weight: .bold, design: .rounded))
            .foregroundStyle(usesCreamStyle ? MaxwinTheme.feltDeep : MaxwinTheme.cream)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 2 : 3)
            .background(
                usesCreamStyle ? MaxwinTheme.cream : MaxwinTheme.badgeGreen,
                in: RoundedRectangle(cornerRadius: 5, style: .continuous)
            )
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

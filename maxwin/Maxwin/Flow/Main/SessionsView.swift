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
            ZStack {
                background

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
            }
            .navigationTitle("Sessions")
            .toolbarBackground(MaxwinTheme.feltDeep.opacity(0.9), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.beginCreateSession()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.gold)
                    }
                }
            }
            .task {
                if viewModel.sessions.isEmpty {
                    await viewModel.load()
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .sheet(isPresented: $viewModel.isEditorPresented) {
                if let editorViewModel = viewModel.editorViewModel {
                    SessionEditorView(viewModel: editorViewModel) {
                        await viewModel.handleEditorSaved()
                    }
                }
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

    private var background: some View {
        MaxwinTheme.felt
            .ignoresSafeArea()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(MaxwinTheme.gold)
            Text("No sessions yet")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(MaxwinTheme.cream)
            Text("Log your first cash game or tournament.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
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
                    sessionCard(session)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func sessionCard(_ session: PokerSession) -> some View {
        let expanded = viewModel.isSessionExpanded(session.id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.toggleSessionExpanded(session.id)
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
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

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(CurrencyFormatting.signedString(from: session.profit))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(session.profit >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed)

                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.gold)
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if expanded {
                Divider()
                    .background(MaxwinTheme.fieldStroke)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        statLabel("Buy-in", value: CurrencyFormatting.string(from: session.buyIn))
                        Spacer()
                        statLabel("Cash-out", value: CurrencyFormatting.string(from: session.cashOut))
                    }

                    HStack(spacing: 12) {
                        Button {
                            viewModel.beginEditSession(session)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(MaxwinTheme.gold)
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            viewModel.requestDelete(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(MaxwinTheme.lossRed)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isMutating)

                        Spacer()
                    }

                    Text("Hands")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.gold)
                        .padding(.top, 2)

                    if session.hands.isEmpty {
                        Text("No hands logged for this session.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(MaxwinTheme.mutedCream)
                    } else {
                        ForEach(session.hands) { hand in
                            handRow(hand)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
        }
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func handRow(_ hand: Hand) -> some View {
        let detail = viewModel.detail(for: hand)
        let expanded = viewModel.isHandExpanded(hand.id)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleHandExpanded(hand.id)
                }
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("#\(hand.handNumber) · \(hand.position)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(MaxwinTheme.cream)

                            Text(hand.holeCards)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(MaxwinTheme.mutedCream)
                        }

                        if let notes = hand.notes, !notes.isEmpty, !expanded {
                            Text(notes)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(MaxwinTheme.mutedCream.opacity(0.85))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(CurrencyFormatting.signedString(from: hand.result))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(hand.result >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed)

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MaxwinTheme.gold.opacity(0.9))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let notes = hand.notes, !notes.isEmpty {
                        detailLine(title: "Notes", value: notes)
                    }

                    if let detail {
                        handDetailBreakdown(detail)
                    } else {
                        Text("No extra hand detail logged.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(MaxwinTheme.mutedCream.opacity(0.85))
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MaxwinTheme.feltDeep.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.vertical, 6)
    }

    private func handDetailBreakdown(_ detail: HandDetail) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let board = detail.board, !board.isEmpty {
                detailLine(title: "Board", value: board)
            }
            if let potSize = detail.potSize {
                detailLine(title: "Pot", value: CurrencyFormatting.string(from: potSize))
            }
            if let opponents = detail.opponents {
                detailLine(title: "Opponents", value: "\(opponents)")
            }
            if let villainHand = detail.villainHand, !villainHand.isEmpty {
                detailLine(title: "Villain", value: villainHand)
            }
            if let allInStreet = detail.allInStreet, !allInStreet.isEmpty {
                detailLine(title: "All-in", value: allInStreet)
            }

            if let streets = detail.streets, !streets.isEmpty {
                Text("Streets")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.gold)
                    .padding(.top, 2)

                ForEach(streets) { street in
                    HStack(alignment: .top, spacing: 6) {
                        Text(street.street)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(MaxwinTheme.cream)
                            .frame(width: 64, alignment: .leading)
                        Text(street.action)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(MaxwinTheme.mutedCream)
                        Spacer(minLength: 4)
                        if let potAfter = street.potAfter {
                            Text(CurrencyFormatting.string(from: potAfter))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(MaxwinTheme.mutedCream)
                        }
                    }
                }
            }
        }
    }

    private func detailLine(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.gold)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)
        }
    }

    private func statLabel(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)
        }
    }
}

#Preview {
    SessionsView(viewModel: SessionsViewModel(sessionService: MockSessionService()))
}

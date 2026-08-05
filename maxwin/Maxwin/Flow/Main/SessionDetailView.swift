//
//  SessionDetailView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct SessionDetailView: View {
    @Bindable var viewModel: SessionsViewModel
    let sessionID: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var expandedHandIDs: Set<UUID> = []

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private var session: PokerSession? {
        viewModel.sessions.first { $0.id == sessionID }
    }

    var body: some View {
        ZStack {
            MaxwinTheme.felt
                .ignoresSafeArea()

            if let session {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summaryCard(session)

                        Divider()
                            .background(MaxwinTheme.fieldStroke)

                        handsSection(session)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            } else {
                Text("Session not found.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
            }
        }
        .navigationTitle(session?.venue ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MaxwinTheme.feltDeep.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let session {
                    Button {
                        Task { await viewModel.toggleSessionFavorite(session) }
                    } label: {
                        Image(systemName: session.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.gold)
                    }
                    .disabled(viewModel.isMutating)
                    .accessibilityLabel(session.isFavorite ? "Remove from favorites" : "Add to favorites")
                }

                Menu {
                    Button {
                        if let session {
                            viewModel.beginEditSession(session)
                        }
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        if let session {
                            viewModel.requestDelete(session)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(viewModel.isMutating)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MaxwinTheme.gold)
                }
            }
        }
        .onChange(of: viewModel.sessions.map(\.id)) { _, ids in
            if !ids.contains(sessionID) {
                dismiss()
            }
        }
    }

    private func summaryCard(_ session: PokerSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.gameType.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.gold)

                    Text(session.stakes)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.cream)

                    Text("\(dateFormatter.string(from: session.date)) · \(session.formattedDuration)")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                }

                Spacer(minLength: 8)

                Text(CurrencyFormatting.signedString(from: session.profit))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(session.profit >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed)
            }

            Divider()
                .background(MaxwinTheme.fieldStroke)

            HStack {
                statLabel("Buy-in", value: CurrencyFormatting.string(from: session.buyIn))
                Spacer()
                statLabel("Cash-out", value: CurrencyFormatting.string(from: session.cashOut))
                Spacer()
                statLabel("Hands", value: "\(session.hands.count)")
            }
        }
        .padding(16)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func handsSection(_ session: PokerSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hand history")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.gold)

            if session.hands.isEmpty {
                Text("No hands logged for this session.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
                    }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(session.hands) { hand in
                        handRow(hand)
                    }
                }
            }
        }
    }

    private func handRow(_ hand: Hand) -> some View {
        let expanded = expandedHandIDs.contains(hand.id)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expanded {
                        expandedHandIDs.remove(hand.id)
                    } else {
                        expandedHandIDs.insert(hand.id)
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("#\(hand.handNumber) · \(hand.position)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(MaxwinTheme.cream)

                            Text(hand.holeCards)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(MaxwinTheme.mutedCream)
                        }

                        if let notes = hand.notes, !notes.isEmpty, !expanded {
                            Text(notes)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(MaxwinTheme.mutedCream.opacity(0.85))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(CurrencyFormatting.signedString(from: hand.result))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(hand.result >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed)

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MaxwinTheme.gold.opacity(0.9))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let notes = hand.notes, !notes.isEmpty {
                        detailLine(title: "Notes", value: notes)
                    }

                    if let detail = hand.detail, detail.hasContent {
                        handDetailBreakdown(detail)
                    } else if hand.notes == nil || hand.notes?.isEmpty == true {
                        Text("No extra hand detail logged.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(MaxwinTheme.mutedCream.opacity(0.85))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
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

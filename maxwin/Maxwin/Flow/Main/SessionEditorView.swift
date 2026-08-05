//
//  SessionEditorView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct SessionEditorView: View {
    @Bindable var viewModel: SessionEditorViewModel
    var onSaved: () async -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                sessionSection
                handsSection

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(MaxwinTheme.lossRed)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .feltScreenBackground()
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MaxwinTheme.cream)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.save() {
                                await onSaved()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(MaxwinTheme.gold)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(MaxwinTheme.gold)
                    .disabled(viewModel.isSaving)
                }
            }
        }
    }

    private var sessionSection: some View {
        Section("Session") {
            DatePicker("Date", selection: $viewModel.draft.date)
                .tint(MaxwinTheme.gold)

            TextField("Venue", text: $viewModel.draft.venue)

            HStack(spacing: 10) {
                Text("Stakes")
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text("SB")
                    .foregroundStyle(MaxwinTheme.mutedCream)
                TextField(
                    "0",
                    value: $viewModel.draft.smallBlind,
                    format: .number.precision(.fractionLength(0...2))
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 44, maxWidth: 64)

                Text("BB")
                    .foregroundStyle(MaxwinTheme.mutedCream)
                TextField(
                    "0",
                    value: $viewModel.draft.bigBlind,
                    format: .number.precision(.fractionLength(0...2))
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 44, maxWidth: 64)
            }

            Picker("Game type", selection: $viewModel.draft.gameType) {
                ForEach(GameType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            TextField(
                "Duration (min)",
                value: $viewModel.draft.durationMinutes,
                format: .number.precision(.fractionLength(0))
            )
            .keyboardType(.numberPad)

            TextField(
                "Buy-in",
                value: $viewModel.draft.buyIn,
                format: .number.precision(.fractionLength(0))
            )
            .keyboardType(.numberPad)

            TextField(
                "Cash-out",
                value: $viewModel.draft.cashOut,
                format: .number.precision(.fractionLength(0))
            )
            .keyboardType(.numberPad)
        }
    }

    private var handsSection: some View {
        Section {
            if viewModel.draft.hands.isEmpty {
                Text("No hands yet. Hands and hand detail are optional.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
            }

            ForEach($viewModel.draft.hands) { $hand in
                handEditor(hand: $hand)
            }

            Button {
                viewModel.addHand()
            } label: {
                Label("Add Hand", systemImage: "plus.circle.fill")
                    .foregroundStyle(MaxwinTheme.gold)
            }
        } header: {
            Text("Hands")
        } footer: {
            Text("Hand detail (board, streets, villain) is optional and can be left off entirely.")
        }
    }

    private func handEditor(hand: Binding<HandDraft>) -> some View {
        let handID = hand.wrappedValue.id
        let expanded = viewModel.isHandExpanded(handID)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleHandExpanded(handID)
                    }
                } label: {
                    HStack {
                        Text("Hand #\(hand.wrappedValue.handNumber)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(MaxwinTheme.cream)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.gold)
                    }
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    viewModel.removeHand(handID)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(MaxwinTheme.lossRed)
                }
                .buttonStyle(.plain)
            }

            if expanded {
                TextField("Position", text: hand.position)
                TextField("Hole cards", text: hand.holeCards)
                TextField(
                    "Result",
                    value: hand.result,
                    format: .currency(code: "USD").precision(.fractionLength(0))
                )
                .keyboardType(.numbersAndPunctuation)
                TextField("Notes", text: hand.notes, axis: .vertical)
                    .lineLimit(2...4)

                Toggle("Include hand detail", isOn: hand.includeDetail)
                    .tint(Color.white.opacity(0.45))

                if hand.wrappedValue.includeDetail {
                    TextField("Board", text: hand.board)
                    TextField(
                        "Pot size",
                        value: hand.potSize,
                        format: .currency(code: "USD").precision(.fractionLength(0))
                    )
                    .keyboardType(.decimalPad)
                    TextField(
                        "Opponents",
                        value: hand.opponents,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    TextField("Villain hand", text: hand.villainHand)
                    TextField("All-in street", text: hand.allInStreet)
                    TextField(
                        "Streets (one per line: Flop: Bet $40)",
                        text: hand.streetsText,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionEditorView(
        viewModel: SessionEditorViewModel(
            draft: .blank(),
            sessionService: MockSessionService()
        ),
        onSaved: {}
    )
}

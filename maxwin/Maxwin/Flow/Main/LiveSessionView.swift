//
//  LiveSessionView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/4/26.
//

import SwiftUI

struct LiveSessionView: View {
    @Bindable var viewModel: LiveSessionViewModel
    var onDiscard: () -> Void

    @State private var showingDiscardConfirm = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case holeCard1, holeCard2, result, notes
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let compact = proxy.size.height < 700
                let sectionSpacing: CGFloat = compact ? 10 : 14
                let cardPadding: CGFloat = compact ? 12 : 14
                let fieldPadding: CGFloat = compact ? 8 : 10

                VStack(spacing: 0) {
                    VStack(spacing: sectionSpacing) {
                        timerSection(compact: compact, cardPadding: cardPadding)
                        handsPlayedSection(compact: compact, cardPadding: cardPadding)
                        currentHandSection(
                            compact: compact,
                            cardPadding: cardPadding,
                            fieldPadding: fieldPadding
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, compact ? 6 : 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    discardBar(compact: compact)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .feltScreenBackground()
            .navigationTitle("Live Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        requestDiscard()
                    }
                    .foregroundStyle(MaxwinTheme.cream)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .foregroundStyle(MaxwinTheme.gold)
                }
            }
            .alert("Discard live session?", isPresented: $showingDiscardConfirm) {
                Button("Discard", role: .destructive) {
                    onDiscard()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can’t be undone. Your timer and hand tracking will be lost.")
            }
        }
    }

    private func timerSection(compact: Bool, cardPadding: CGFloat) -> some View {
        VStack(spacing: compact ? 6 : 10) {
            Text("Elapsed")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)

            HStack(spacing: 14) {
                Group {
                    if viewModel.isPaused {
                        Text(viewModel.formattedElapsed())
                    } else {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(viewModel.formattedElapsed(at: context.date))
                        }
                    }
                }
                .font(.system(size: compact ? 36 : 44, weight: .bold, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(1)

                Button {
                    viewModel.togglePause()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MaxwinTheme.feltDeep)
                        .frame(width: compact ? 40 : 44, height: compact ? 40 : 44)
                        .background(MaxwinTheme.gold, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isPaused ? "Resume session" : "Pause session")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, cardPadding)
        .padding(.horizontal, 14)
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func handsPlayedSection(compact: Bool, cardPadding: CGFloat) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hands played")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)

                Text("\(viewModel.handsPlayed)")
                    .font(.system(size: compact ? 28 : 34, weight: .bold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 8)

            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    viewModel.incrementHandsPlayed()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: compact ? 18 : 20, weight: .bold))
                    .foregroundStyle(
                        viewModel.isPaused
                        ? MaxwinTheme.mutedCream
                        : MaxwinTheme.feltDeep
                    )
                    .frame(width: compact ? 48 : 52, height: compact ? 48 : 52)
                    .background(
                        viewModel.isPaused
                        ? MaxwinTheme.fieldStroke.opacity(0.35)
                        : MaxwinTheme.gold,
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPaused)
            .accessibilityLabel("Add hand played")
        }
        .padding(cardPadding)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func currentHandSection(
        compact: Bool,
        cardPadding: CGFloat,
        fieldPadding: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            Text("Current hand")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.gold)

            VStack(spacing: compact ? 8 : 10) {
                HStack {
                    Text("Position")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)

                    Spacer(minLength: 8)

                    Picker("Position", selection: $viewModel.position) {
                        Text("Select").tag(Optional<PokerPosition>.none)
                        ForEach(PokerPosition.allCases) { position in
                            Text(position.rawValue).tag(Optional(position))
                        }
                    }
                    .labelsHidden()
                    .tint(MaxwinTheme.cream)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, fieldPadding)
                .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack {
                    Text("Hole cards")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)

                    Spacer(minLength: 8)

                    TextField("Kd", text: $viewModel.holeCard1)
                        .focused($focusedField, equals: .holeCard1)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.cream)
                        .frame(width: 48)
                        .padding(.vertical, 4)
                        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    TextField("6d", text: $viewModel.holeCard2)
                        .focused($focusedField, equals: .holeCard2)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.cream)
                        .frame(width: 48)
                        .padding(.vertical, 4)
                        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, fieldPadding)
                .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack {
                    Text("Result")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                    Spacer(minLength: 8)
                    TextField(
                        "0",
                        value: $viewModel.result,
                        format: .number.precision(.fractionLength(0))
                    )
                    .keyboardType(.numbersAndPunctuation)
                    .focused($focusedField, equals: .result)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, fieldPadding)
                .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack {
                    Text("Notes")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                    Spacer(minLength: 8)
                    TextField("Optional", text: $viewModel.notes)
                        .focused($focusedField, equals: .notes)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(MaxwinTheme.cream)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, fieldPadding)
                .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func discardBar(compact: Bool) -> some View {
        Button {
            requestDiscard()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                Text("Discard session")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(MaxwinTheme.lossRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 12 : 14)
            .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(MaxwinTheme.lossRed.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, compact ? 8 : 10)
        .padding(.bottom, compact ? 8 : 10)
    }

    private func requestDiscard() {
        showingDiscardConfirm = true
    }
}

#Preview {
    LiveSessionView(viewModel: LiveSessionViewModel(), onDiscard: {})
}

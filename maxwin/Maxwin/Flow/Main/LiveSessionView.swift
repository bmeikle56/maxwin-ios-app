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
        case position, holeCards, result, notes
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        timerSection
                        handsPlayedSection
                        currentHandSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }

                discardBar
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

    private var timerSection: some View {
        VStack(spacing: 12) {
            Text("Elapsed")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)

            HStack(spacing: 16) {
                Group {
                    if viewModel.isPaused {
                        Text(viewModel.formattedElapsed())
                    } else {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(viewModel.formattedElapsed(at: context.date))
                        }
                    }
                }
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)

                Button {
                    viewModel.togglePause()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MaxwinTheme.feltDeep)
                        .frame(width: 44, height: 44)
                        .background(MaxwinTheme.gold, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isPaused ? "Resume session" : "Pause session")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private var handsPlayedSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hands played")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)

                Text("\(viewModel.handsPlayed)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
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
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        viewModel.isPaused
                        ? MaxwinTheme.mutedCream
                        : MaxwinTheme.feltDeep
                    )
                    .frame(width: 56, height: 56)
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
        .padding(18)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private var currentHandSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current hand")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.gold)

            Text("Track one hand at a time. Tap + to count it and clear for the next.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)

            VStack(spacing: 12) {
                liveField("Position", text: $viewModel.position, field: .position)
                liveField("Hole cards", text: $viewModel.holeCards, field: .holeCards)

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
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                    TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .lineLimit(2...4)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(MaxwinTheme.cream)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func liveField(_ title: String, text: Binding<String>, field: Field) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
            Spacer(minLength: 8)
            TextField(title, text: text)
                .focused($focusedField, equals: field)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var discardBar: some View {
        Button {
            requestDiscard()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
                Text("Discard session")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(MaxwinTheme.lossRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MaxwinTheme.lossRed.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(MaxwinTheme.felt.opacity(0.92))
    }

    private func requestDiscard() {
        showingDiscardConfirm = true
    }
}

#Preview {
    LiveSessionView(viewModel: LiveSessionViewModel(), onDiscard: {})
}

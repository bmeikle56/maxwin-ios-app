//
//  TrackView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct TrackView: View {
    @Bindable var viewModel: TrackViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                MaxwinTheme.felt
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    rangePicker

                    if viewModel.isLoading {
                        loadingContent
                    } else {
                        summaryHeader
                        chartCard
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Track")
            .toolbarBackground(MaxwinTheme.feltDeep.opacity(0.9), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                Task { await viewModel.load() }
            }
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach(DateRangeFilter.allCases) { range in
                Button {
                    Task { await viewModel.selectRange(range) }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            viewModel.selectedRange == range
                            ? MaxwinTheme.feltDeep
                            : MaxwinTheme.cream
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedRange == range
                            ? MaxwinTheme.gold
                            : MaxwinTheme.fieldFill,
                            in: Capsule()
                        )
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    viewModel.selectedRange == range
                                    ? Color.clear
                                    : MaxwinTheme.fieldStroke,
                                    lineWidth: 1
                                )
                        }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cumulative winnings")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)

            Text(CurrencyFormatting.signedString(from: viewModel.totalProfit))
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(
                    viewModel.totalProfit >= 0
                    ? MaxwinTheme.winGreen
                    : MaxwinTheme.lossRed
                )
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(MaxwinTheme.gold)
                .scaleEffect(1.15)

            Text("Loading winnings…")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(16)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private var chartCard: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else if viewModel.points.isEmpty {
                Text("No sessions in this range yet.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                WinningsChartView(
                    points: viewModel.points,
                    animationsEnabled: viewModel.animationsEnabled,
                    showYAxisLabels: viewModel.showYAxisLabels
                )
                .frame(maxWidth: .infinity)
                .frame(height: 260)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }
}

#Preview {
    TrackView(
        viewModel: TrackViewModel(
            earningsService: MockEarningsService(sessionService: MockSessionService())
        )
    )
}

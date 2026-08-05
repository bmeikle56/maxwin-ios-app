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
            VStack(alignment: .leading, spacing: 20) {
                rangePicker

                if viewModel.isLoading {
                    loadingContent
                } else {
                    summaryHeader
                    metricsSection
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .feltScreenBackground()
            .navigationTitle("Track")
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
                            ? MaxwinTheme.cream
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
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Shared gap: chart↔stats and cell↔cell.
    private let metricsGap: CGFloat = 16
    /// Keeps vertical dividers from meeting the horizontal rule.
    private let dividerInset: CGFloat = 14

    private var metricsSection: some View {
        VStack(spacing: 0) {
            chartCard

            horizontalMetricsDivider

            HStack(spacing: 0) {
                statTile(
                    title: "Avg BB/100",
                    value: formattedBBPer100,
                    valueColor: bbPer100Color
                )

                verticalMetricsDivider

                statTile(
                    title: "Avg length",
                    value: formattedAverageLength,
                    valueColor: MaxwinTheme.cream
                )

                verticalMetricsDivider

                statTile(
                    title: "Win rate",
                    value: formattedWinRate,
                    valueColor: MaxwinTheme.cream
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var horizontalMetricsDivider: some View {
        Capsule()
            .fill(MaxwinTheme.divider)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, (metricsGap - 1) / 2)
    }

    private var verticalMetricsDivider: some View {
        Color.clear
            .frame(width: metricsGap)
            .overlay {
                Capsule()
                    .fill(MaxwinTheme.divider)
                    .frame(width: 1)
                    .padding(.vertical, dividerInset)
            }
    }

    private func statTile(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var formattedBBPer100: String {
        guard let value = viewModel.averageBBPer100 else { return "—" }
        let formatted = String(format: "%.1f", abs(value))
        if value > 0 { return "+\(formatted)" }
        if value < 0 { return "-\(formatted)" }
        return "0.0"
    }

    private var bbPer100Color: Color {
        guard let value = viewModel.averageBBPer100 else { return MaxwinTheme.mutedCream }
        if value > 0 { return MaxwinTheme.winGreen }
        if value < 0 { return MaxwinTheme.lossRed }
        return MaxwinTheme.cream
    }

    private var formattedAverageLength: String {
        guard let minutes = viewModel.averageSessionMinutes else { return "—" }
        return PokerSession.formatDuration(minutes: minutes)
    }

    private var formattedWinRate: String {
        guard let rate = viewModel.sessionWinRate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }
}

#Preview {
    TrackView(
        viewModel: TrackViewModel(
            earningsService: MockEarningsService(sessionService: MockSessionService()),
            sessionService: MockSessionService()
        )
    )
}

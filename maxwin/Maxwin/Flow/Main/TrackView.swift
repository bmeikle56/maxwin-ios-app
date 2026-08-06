//
//  TrackView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct TrackView: View {
    @Bindable var viewModel: TrackViewModel
    @Bindable var sessionsViewModel: SessionsViewModel
    var isSelected: Bool = true

    /// 0 → 1 progress so every metric always starts at zero, then moves toward its target.
    @State private var metricsProgress: Double = 0
    @State private var metricsGeneration = 0
    @State private var metricsAnimationTask: Task<Void, Never>?
    @State private var showingBBPer100Info = false
    @State private var jesterWiggle = false
    @State private var jesterAnimationTask: Task<Void, Never>?

    private let metricsCountDuration: TimeInterval = 2.55
    private let jesterAnimationInterval: Duration = .seconds(8)

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .leading, spacing: 20) {
                    rangePicker

                    if viewModel.isLoading {
                        loadingContent
                    } else {
                        summaryHeader
                        metricsSection
                    }

                    quickActionsSection

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                if showingBBPer100Info {
                    bbPer100InfoOverlay
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .feltScreenBackground()
            .toolbar(.hidden, for: .navigationBar)
            .animation(.easeInOut(duration: 0.22), value: showingBBPer100Info)
            .onAppear {
                Task { await appearOnTrackTab() }
            }
            .onChange(of: isSelected) { _, selected in
                guard selected else {
                    stopJesterAnimationLoop()
                    return
                }
                Task { await appearOnTrackTab() }
                restartJesterAnimationLoop()
            }
            .onChange(of: metricsAnimationKey) { _, _ in
                animateMetrics()
            }
            .onChange(of: viewModel.animationsEnabled) { _, _ in
                restartJesterAnimationLoop()
            }
            .onChange(of: viewModel.tipsEnabled) { _, enabled in
                if enabled {
                    restartJesterAnimationLoop()
                } else {
                    stopJesterAnimationLoop()
                }
            }
        }
    }

    /// Re-triggers the count-up when range or underlying stats change.
    private var metricsAnimationKey: String {
        let bb = viewModel.averageBBPer100.map(String.init(describing:)) ?? "nil"
        let minutes = viewModel.averageSessionMinutes.map { String($0) } ?? "nil"
        let winRate = viewModel.sessionWinRate.map(String.init(describing:)) ?? "nil"
        return "\(viewModel.selectedRange.rawValue)|\(bb)|\(minutes)|\(winRate)|\(viewModel.isLoading)"
    }

    private func appearOnTrackTab() async {
        await viewModel.load()
        animateMetrics()
        restartJesterAnimationLoop()
    }

    private var rangePicker: some View {
        HStack(spacing: 6) {
            ForEach(DateRangeFilter.allCases) { range in
                Button {
                    viewModel.selectRange(range)
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            viewModel.selectedRange == range
                            ? MaxwinTheme.feltDeep
                            : MaxwinTheme.cream
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
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
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Text(totalProfitLabel)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(totalProfitColor)

                Capsule()
                    .fill(MaxwinTheme.headerGray.opacity(0.4))
                    .frame(width: 1, height: 18)

                Text(hoursPlayedLabel)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.headerGray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            if viewModel.tipsEnabled {
                betBiggerBanner
            }
        }
    }

    private var hoursPlayedLabel: String {
        let hours = viewModel.totalHoursPlayed
        return hours == 1 ? "1 hr" : "\(hours) hrs"
    }

    private var totalProfitLabel: String {
        let profit = viewModel.totalProfit
        if profit > 0 {
            return CurrencyFormatting.string(from: profit)
        }
        return CurrencyFormatting.signedString(from: profit)
    }

    private var totalProfitColor: Color {
        let profit = viewModel.totalProfit
        if profit > 0 { return MaxwinTheme.winGreen }
        if profit < 0 { return MaxwinTheme.lossRed }
        return .white
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
                    drawProgress: metricsProgress
                )
                .frame(maxWidth: .infinity)
                .frame(height: 260)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Shared gap: chart↔stats.
    private let metricsGap: CGFloat = 16
    /// Gap between the paired stat tiles / quick actions.
    private let pairedContentGap: CGFloat = 32
    private let tipPadding: CGFloat = 8
    private let jesterSize: CGFloat = 28
    private let tipTextInset: CGFloat = 6
    /// Translucent fill shared by quick actions and stat tiles.
    private let translucentPanelFill = Color(white: 0.42).opacity(0.18)

    private var metricsSection: some View {
        VStack(spacing: metricsGap) {
            chartCard

            HStack(alignment: .top, spacing: pairedContentGap) {
                statTile(title: "BB/100", showsInfo: true) {
                    if let target = viewModel.averageBBPer100 {
                        AnimatedBBPer100Text(value: target * metricsProgress)
                            .id("bb-\(metricsGeneration)")
                    } else {
                        placeholderMetric
                    }
                }
                .frame(width: quickActionSide)

                // statTile(title: "Avg length") {
                //     if let target = viewModel.averageSessionMinutes {
                //         AnimatedDurationText(minutes: Double(target) * metricsProgress)
                //             .id("duration-\(metricsGeneration)")
                //     } else {
                //         placeholderMetric
                //     }
                // }

                statTile(title: "Win rate") {
                    if let target = viewModel.sessionWinRate {
                        AnimatedWinRateText(rate: target * metricsProgress)
                            .id("winrate-\(metricsGeneration)")
                    } else {
                        placeholderMetric
                    }
                }
                .frame(width: quickActionSide)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private let quickActionSide: CGFloat = 112

    private var quickActionsSection: some View {
        HStack(spacing: pairedContentGap) {
            quickActionButton(
                title: "Record",
                subtitle: "Live session",
                systemImage: "record.circle"
            ) {
                sessionsViewModel.beginLiveSession()
            }

            quickActionButton(
                title: "Log",
                subtitle: "Past session",
                systemImage: "plus.circle"
            ) {
                sessionsViewModel.beginCreateSession()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func quickActionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(MaxwinTheme.cream)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.cream)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                }
            }
            .frame(width: quickActionSide, height: quickActionSide)
            .background(
                translucentPanelFill,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private var betBiggerBanner: some View {
        HStack(alignment: .center, spacing: 6) {
            Image("Jester")
                .resizable()
                .scaledToFit()
                .frame(width: jesterSize, height: jesterSize)
                .rotationEffect(.degrees(jesterWiggle ? 16 : 0))
                .scaleEffect(jesterWiggle ? 1.14 : 1)
                .offset(y: jesterWiggle ? -2 : 0)
                .accessibilityHidden(true)

            Text("Bet bigger!")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, tipTextInset)
                .padding(.vertical, tipTextInset - 1)
                .background(
                    MaxwinTheme.fieldFill,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .padding(tipPadding)
        .background(
            Color(white: 0.06),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private func restartJesterAnimationLoop() {
        stopJesterAnimationLoop()

        guard viewModel.animationsEnabled, viewModel.tipsEnabled, isSelected else { return }

        jesterAnimationTask = Task { @MainActor in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: jesterAnimationInterval)
                } catch {
                    return
                }

                guard !Task.isCancelled,
                      viewModel.animationsEnabled,
                      viewModel.tipsEnabled,
                      isSelected
                else { return }

                await playJesterWiggle()
            }
        }
    }

    private func stopJesterAnimationLoop() {
        jesterAnimationTask?.cancel()
        jesterAnimationTask = nil
        jesterWiggle = false
    }

    private func playJesterWiggle() async {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.38)) {
            jesterWiggle = true
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            jesterWiggle = false
        }
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.36)) {
            jesterWiggle = true
        }
        try? await Task.sleep(for: .milliseconds(260))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.62)) {
            jesterWiggle = false
        }
    }

    private var bbPer100InfoOverlay: some View {
        ZStack {
            ZStack {
                Color.black.opacity(0.22)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.35)
            }
            .ignoresSafeArea()
            .onTapGesture {
                showingBBPer100Info = false
            }

            VStack(spacing: 14) {
                Text("BB/100")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)

                Text("Big blinds won or lost per 100 hands. It normalizes your results across different stakes and session lengths so you can compare performance over time.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    showingBBPer100Info = false
                } label: {
                    Text("Got it")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.feltDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MaxwinTheme.cream, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(22)
            .frame(maxWidth: 300)
            .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
            }
            .padding(.horizontal, 32)
        }
    }

    private var placeholderMetric: some View {
        Text("—")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(MaxwinTheme.mutedCream)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
    }

    private func statTile<Content: View>(
        title: String,
        showsInfo: Bool = false,
        @ViewBuilder value: () -> Content
    ) -> some View {
        VStack(spacing: 22) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if showsInfo {
                    Button {
                        showingBBPer100Info = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MaxwinTheme.mutedCream.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("What is BB/100?")
                }
            }
            .padding(4)
            .background(
                Color(white: 0.42).opacity(0.18),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )

            value()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 16)
        .padding(.horizontal, 4)
        .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func animateMetrics() {
        guard !viewModel.isLoading else { return }

        metricsAnimationTask?.cancel()

        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            metricsProgress = 0
            metricsGeneration += 1
        }

        guard viewModel.animationsEnabled else {
            metricsProgress = 1
            return
        }

        // Commit the zero frame before counting toward the target (pos or neg).
        // Strong ease-out: starts quick, then decelerates hard as it nears the final value.
        metricsAnimationTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(.timingCurve(0.05, 0.7, 0.1, 1.0, duration: metricsCountDuration)) {
                metricsProgress = 1
            }
        }
    }
}

// MARK: - Animated metric values

private struct AnimatedBBPer100Text: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    /// Soft-maps (−∞, ∞) → (−1, 1); ~±20 bb/100 is strongly saturated.
    private var normalized: Double {
        MetricHeat.normalized(value, scale: 20)
    }

    private var fireIntensity: Double {
        MetricHeat.fireIntensity(normalized: normalized)
    }

    private var iceIntensity: Double {
        MetricHeat.iceIntensity(normalized: normalized)
    }

    var body: some View {
        Text(formatted)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(MetricHeat.signedHeatColor(normalized: normalized))
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .background {
                GeometryReader { proxy in
                    let width = max(proxy.size.width * 1.85, 72)
                    let height = max(proxy.size.height * 2.4, 40)
                    ZStack {
                        if fireIntensity > 0 {
                            MetricFireAura(intensity: fireIntensity, width: width, height: height)
                        }
                        if iceIntensity > 0 {
                            MetricIceAura(intensity: iceIntensity, width: width, height: height)
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
    }

    private var formatted: String {
        String(format: "%.1f", value)
    }
}

private struct AnimatedDurationText: View, Animatable {
    var minutes: Double

    var animatableData: Double {
        get { minutes }
        set { minutes = newValue }
    }

    var body: some View {
        Text(PokerSession.formatDuration(minutes: Int(minutes.rounded())))
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(MaxwinTheme.cream)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
    }
}

private struct AnimatedWinRateText: View, Animatable {
    var rate: Double

    var animatableData: Double {
        get { rate }
        set { rate = newValue }
    }

    /// Fire ramps from just above break-even (0.5) to full at 1.0.
    private var fireIntensity: Double {
        max(0, min(1, (rate - 0.5) / 0.5))
    }

    /// Ice ramps from just below break-even (0.5) to full at 0.0.
    private var iceIntensity: Double {
        max(0, min(1, (0.5 - rate) / 0.5))
    }

    var body: some View {
        Text(String(format: "%.2f", rate))
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(MetricHeat.rateHeatColor(rate))
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .background {
                ZStack {
                    if fireIntensity > 0 {
                        MetricFireAura(intensity: fireIntensity)
                    }
                    if iceIntensity > 0 {
                        MetricIceAura(intensity: iceIntensity)
                    }
                }
            }
    }
}

#Preview {
    TrackView(
        viewModel: TrackViewModel(
            trackDataService: MockTrackDataService(sessionService: MockSessionService())
        ),
        sessionsViewModel: SessionsViewModel(
            sessionService: MockSessionService(),
            trackDataService: MockTrackDataService(sessionService: MockSessionService())
        )
    )
}

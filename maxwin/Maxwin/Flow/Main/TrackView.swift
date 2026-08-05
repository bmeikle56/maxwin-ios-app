//
//  TrackView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct TrackView: View {
    @Bindable var viewModel: TrackViewModel
    var isSelected: Bool = true

    /// 0 → 1 progress so every metric always starts at zero, then moves toward its target.
    @State private var metricsProgress: Double = 0
    @State private var metricsGeneration = 0
    @State private var metricsAnimationTask: Task<Void, Never>?
    @State private var showingBBPer100Info = false

    private let metricsCountDuration: TimeInterval = 2.55

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

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

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
                guard selected else { return }
                Task { await appearOnTrackTab() }
            }
            .onChange(of: metricsAnimationKey) { _, _ in
                animateMetrics()
            }
        }
    }

    /// Re-triggers the count-up when range or underlying stats change.
    private var metricsAnimationKey: String {
        let bb = viewModel.averageBBPer100.map(String.init(describing:)) ?? "nil"
        let minutes = viewModel.averageSessionMinutes.map(String.init) ?? "nil"
        let winRate = viewModel.sessionWinRate.map(String.init(describing:)) ?? "nil"
        return "\(viewModel.selectedRange.rawValue)|\(bb)|\(minutes)|\(winRate)|\(viewModel.isLoading)"
    }

    private func appearOnTrackTab() async {
        await viewModel.load()
        animateMetrics()
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Cumulative winnings")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.headerGray)

                Text(CurrencyFormatting.signedString(from: viewModel.totalProfit))
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(MaxwinTheme.headerGray)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text("Hours played")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.headerGray)

                Text(PokerSession.formatDuration(minutes: viewModel.totalMinutesPlayed))
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(MaxwinTheme.headerGray)
                    .multilineTextAlignment(.trailing)
            }
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

    /// Shared gap: chart↔stats and cell↔cell.
    private let metricsGap: CGFloat = 16
    /// Keeps vertical dividers from meeting the horizontal rule.
    private let dividerInset: CGFloat = 14

    private var metricsSection: some View {
        VStack(spacing: 0) {
            chartCard

            horizontalMetricsDivider

            HStack(spacing: 0) {
                statTile(title: "BB/100", showsInfo: true) {
                    if let target = viewModel.averageBBPer100 {
                        AnimatedBBPer100Text(
                            value: target * metricsProgress,
                            animationsEnabled: viewModel.animationsEnabled
                        )
                            .id("bb-\(metricsGeneration)")
                    } else {
                        placeholderMetric
                    }
                }

                verticalMetricsDivider

                statTile(title: "Avg length") {
                    if let target = viewModel.averageSessionMinutes {
                        AnimatedDurationText(minutes: Double(target) * metricsProgress)
                            .id("duration-\(metricsGeneration)")
                    } else {
                        placeholderMetric
                    }
                }

                verticalMetricsDivider

                statTile(title: "Win rate") {
                    if let target = viewModel.sessionWinRate {
                        AnimatedWinRateText(
                            rate: target * metricsProgress,
                            animationsEnabled: viewModel.animationsEnabled
                        )
                            .id("winrate-\(metricsGeneration)")
                    } else {
                        placeholderMetric
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            betBiggerBanner
                .padding(.top, metricsGap)
        }
    }

    private var betBiggerBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            Image("Jester")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            Text("You gotta bet bigger!")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(white: 0.18).opacity(0.35),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
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

    private func statTile<Content: View>(
        title: String,
        showsInfo: Bool = false,
        @ViewBuilder value: () -> Content
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .multilineTextAlignment(.center)

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

            value()
        }
        .frame(maxWidth: .infinity)
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
    var animationsEnabled: Bool = true

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    /// Soft-maps (−∞, ∞) → (−1, 1); ~±20 bb/100 is strongly saturated.
    private var normalized: Double {
        tanh(value / 20)
    }

    /// Ramps in above ~0.7 (~+17 bb/100), full as value → +∞.
    private var fireIntensity: Double {
        max(0, min(1, (normalized - 0.7) / 0.3))
    }

    /// Ramps in below ~−0.7 (~−17 bb/100), full as value → −∞.
    private var iceIntensity: Double {
        max(0, min(1, (-0.7 - normalized) / 0.3))
    }

    var body: some View {
        Text(formatted)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(bbPer100Color(for: normalized))
            .minimumScaleFactor(0.8)
            .lineLimit(1)
            .background {
                if animationsEnabled {
                    GeometryReader { proxy in
                        let width = max(proxy.size.width * 1.85, 72)
                        let height = max(proxy.size.height * 2.4, 40)
                        ZStack {
                            if fireIntensity > 0.01 {
                                WinRateFireAura(intensity: fireIntensity, width: width, height: height)
                            }
                            if iceIntensity > 0.01 {
                                WinRateIceAura(intensity: iceIntensity, width: width, height: height)
                            }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
            }
    }

    private var formatted: String {
        String(format: "%.1f", value)
    }

    /// −1 → 0: light blue ice → white. 0 → +1: white → bright orange-yellow fire.
    private func bbPer100Color(for t: Double) -> Color {
        let clamped = min(max(t, -1), 1)
        let lightBlue = (r: 0.78, g: 0.93, b: 1.0)
        let white = (r: 1.0, g: 1.0, b: 1.0)
        let fire = (r: 1.0, g: 0.62, b: 0.14)

        if clamped <= 0 {
            let u = clamped + 1 // −1 → 0, 0 → 1
            return Color(
                red: lightBlue.r + (white.r - lightBlue.r) * u,
                green: lightBlue.g + (white.g - lightBlue.g) * u,
                blue: lightBlue.b + (white.b - lightBlue.b) * u
            )
        }

        return Color(
            red: white.r + (fire.r - white.r) * clamped,
            green: white.g + (fire.g - white.g) * clamped,
            blue: white.b + (fire.b - white.b) * clamped
        )
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
    var animationsEnabled: Bool = true

    var animatableData: Double {
        get { rate }
        set { rate = newValue }
    }

    /// Ramps in above ~85%, full at 100%.
    private var fireIntensity: Double {
        max(0, min(1, (rate - 0.85) / 0.15))
    }

    /// Ramps in below ~15%, full at 0%.
    private var iceIntensity: Double {
        max(0, min(1, (0.15 - rate) / 0.15))
    }

    var body: some View {
        ZStack {
            if animationsEnabled {
                if fireIntensity > 0.01 {
                    WinRateFireAura(intensity: fireIntensity)
                }
                if iceIntensity > 0.01 {
                    WinRateIceAura(intensity: iceIntensity)
                }
            }

            Text("\(Int((rate * 100).rounded()))")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(winRateColor(for: rate))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
    }

    /// 0–50%: very light blue → white. 51–100%: white → bright fire orange/red.
    private func winRateColor(for rate: Double) -> Color {
        let t = min(max(rate, 0), 1)
        let lightBlue = (r: 0.78, g: 0.93, b: 1.0)
        let white = (r: 1.0, g: 1.0, b: 1.0)
        let fire = (r: 1.0, g: 0.28, b: 0.06)

        if t <= 0.5 {
            let u = t / 0.5
            return Color(
                red: lightBlue.r + (white.r - lightBlue.r) * u,
                green: lightBlue.g + (white.g - lightBlue.g) * u,
                blue: lightBlue.b + (white.b - lightBlue.b) * u
            )
        }

        let u = (t - 0.5) / 0.5
        return Color(
            red: white.r + (fire.r - white.r) * u,
            green: white.g + (fire.g - white.g) * u,
            blue: white.b + (fire.b - white.b) * u
        )
    }
}

private struct WinRateFireAura: View {
    var intensity: Double
    var width: CGFloat = 64
    var height: CGFloat = 36

    var body: some View {
        let scaleX = width / 64
        let scaleY = height / 36

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    let phase = Double(index) * 0.9
                    let flicker = 0.65 + 0.35 * sin(t * (4.2 + Double(index) * 0.7) + phase)
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.55, blue: 0.12).opacity(0.45 * intensity * flicker),
                                    Color(red: 0.85, green: 0.22, blue: 0.04).opacity(0.35 * intensity * flicker),
                                    Color(red: 0.55, green: 0.06, blue: 0.01).opacity(0.18 * intensity),
                                    Color.clear
                                ],
                                center: UnitPoint(
                                    x: 0.5 + 0.08 * sin(t * 3.1 + phase),
                                    y: 0.55 + 0.1 * cos(t * 2.4 + phase)
                                ),
                                startRadius: 0,
                                endRadius: (26 + CGFloat(index) * 3) * max(scaleX, scaleY)
                            )
                        )
                        .frame(
                            width: (34 + CGFloat(index) * 5) * scaleX,
                            height: (20 + CGFloat(index) * 3.5) * scaleY
                        )
                        .offset(
                            x: CGFloat(sin(t * (2.8 + Double(index) * 0.45) + phase)) * (2.5 + CGFloat(index)) * intensity * scaleX,
                            y: CGFloat(cos(t * (3.4 + Double(index) * 0.35) + phase)) * (1.5 + CGFloat(index) * 0.4) * intensity * scaleY
                                - CGFloat(index) * 0.8 * scaleY
                        )
                        .blur(radius: (3.5 + CGFloat(index) * 0.8) * max(scaleX, scaleY))
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

private struct WinRateIceAura: View {
    var intensity: Double
    var width: CGFloat = 64
    var height: CGFloat = 36

    var body: some View {
        let scaleX = width / 64
        let scaleY = height / 36

        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    let phase = Double(index) * 1.1
                    let shimmer = 0.7 + 0.3 * sin(t * (2.6 + Double(index) * 0.5) + phase)
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.72, blue: 0.92).opacity(0.4 * intensity * shimmer),
                                    Color(red: 0.22, green: 0.48, blue: 0.78).opacity(0.28 * intensity * shimmer),
                                    Color(red: 0.1, green: 0.28, blue: 0.55).opacity(0.14 * intensity),
                                    Color.clear
                                ],
                                center: UnitPoint(
                                    x: 0.5 + 0.06 * cos(t * 1.8 + phase),
                                    y: 0.5 + 0.08 * sin(t * 2.1 + phase)
                                ),
                                startRadius: 0,
                                endRadius: (24 + CGFloat(index) * 3) * max(scaleX, scaleY)
                            )
                        )
                        .frame(
                            width: (32 + CGFloat(index) * 5) * scaleX,
                            height: (20 + CGFloat(index) * 3) * scaleY
                        )
                        .offset(
                            x: CGFloat(cos(t * (1.9 + Double(index) * 0.4) + phase)) * (2 + CGFloat(index)) * intensity * scaleX,
                            y: CGFloat(sin(t * (2.2 + Double(index) * 0.35) + phase)) * (1.5 + CGFloat(index) * 0.35) * intensity * scaleY
                        )
                        .blur(radius: (3 + CGFloat(index) * 0.7) * max(scaleX, scaleY))
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

#Preview {
    TrackView(
        viewModel: TrackViewModel(
            trackDataService: MockTrackDataService(sessionService: MockSessionService())
        )
    )
}

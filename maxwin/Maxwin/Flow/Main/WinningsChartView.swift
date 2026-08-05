//
//  WinningsChartView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct WinningsChartView: View {
    let points: [EarningsDataPoint]
    var animationsEnabled: Bool = true
    var showYAxisLabels: Bool = true

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private let plotVerticalPadding: CGFloat = 16
    private let plotHorizontalPadding: CGFloat = 28
    private let lineWidth: CGFloat = 1.5
    private let pointDotRadius: CGFloat = 2.5

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let size = proxy.size
                let chartWidth = max(size.width, 1)
                let plotLeading = plotHorizontalPadding
                let plotWidth = max(chartWidth - plotHorizontalPadding * 2, 1)
                let plotTop = plotVerticalPadding
                let plotBottom = size.height - plotVerticalPadding
                let plotHeight = max(plotBottom - plotTop, 1)

                Canvas { context, _ in
                    guard points.count >= 1 else { return }

                    let values = points.map(\.cumulativeProfit)
                    let dataMin = values.min() ?? 0
                    let dataMax = values.max() ?? 0
                    // Include zero so the baseline stays visible, then stretch to fill the plot.
                    var domainMin = min(0, dataMin)
                    var domainMax = max(0, dataMax)
                    if abs(domainMax - domainMin) < 0.000_1 {
                        domainMin -= 1
                        domainMax += 1
                    }
                    let domainSpan = domainMax - domainMin

                    let zeroY = yPosition(
                        for: 0,
                        domainMin: domainMin,
                        domainSpan: domainSpan,
                        plotTop: plotTop,
                        plotHeight: plotHeight
                    )

                    let stepX = points.count == 1
                        ? 0
                        : plotWidth / CGFloat(points.count - 1)

                    let xForIndex: (Int) -> CGFloat = { index in
                        plotLeading + CGFloat(index) * stepX
                    }

                    let yForValue: (Double) -> CGFloat = { value in
                        yPosition(
                            for: value,
                            domainMin: domainMin,
                            domainSpan: domainSpan,
                            plotTop: plotTop,
                            plotHeight: plotHeight
                        )
                    }

                    drawGuideLine(
                        at: zeroY,
                        fromX: 0,
                        width: chartWidth,
                        opacity: 0.85,
                        in: &context
                    )

                    let extremesDiffer = abs(dataMax - dataMin) > 0.000_1

                    if abs(dataMax) > 0.000_1 {
                        drawGuideLine(
                            at: yForValue(dataMax),
                            fromX: 0,
                            width: chartWidth,
                            opacity: 0.22,
                            in: &context
                        )
                    }

                    if abs(dataMin) > 0.000_1, extremesDiffer || abs(dataMax) <= 0.000_1 {
                        drawGuideLine(
                            at: yForValue(dataMin),
                            fromX: 0,
                            width: chartWidth,
                            opacity: 0.22,
                            in: &context
                        )
                    }

                    guard points.count >= 2 else {
                        if showYAxisLabels {
                            drawPointMarker(
                                at: CGPoint(x: chartWidth / 2, y: yForValue(values[0])),
                                value: values[0],
                                plotTop: plotTop,
                                plotBottom: plotBottom,
                                horizontalAnchor: .center,
                                in: &context
                            )
                        }
                        return
                    }

                    for index in 0..<(points.count - 1) {
                        let startValue = values[index]
                        let endValue = values[index + 1]
                        let start = CGPoint(
                            x: xForIndex(index),
                            y: yForValue(startValue)
                        )
                        let end = CGPoint(
                            x: xForIndex(index + 1),
                            y: yForValue(endValue)
                        )

                        drawSegment(
                            from: start,
                            to: end,
                            startValue: startValue,
                            endValue: endValue,
                            zeroY: zeroY,
                            in: &context
                        )
                    }

                    if showYAxisLabels {
                        for index in values.indices {
                            let horizontalAnchor: LabelHorizontalAlignment = {
                                if index == 0 { return .leading }
                                if index == values.count - 1 { return .trailing }
                                return .center
                            }()
                            drawPointMarker(
                                at: CGPoint(x: xForIndex(index), y: yForValue(values[index])),
                                value: values[index],
                                plotTop: plotTop,
                                plotBottom: plotBottom,
                                horizontalAnchor: horizontalAnchor,
                                in: &context
                            )
                        }
                    }
                }
                .animation(
                    animationsEnabled ? .easeInOut(duration: 0.35) : nil,
                    value: points.map(\.id)
                )
                .animation(
                    animationsEnabled ? .easeInOut(duration: 0.25) : nil,
                    value: showYAxisLabels
                )
            }

            dateAxis
        }
    }

    private var dateAxis: some View {
        HStack(spacing: 0) {
            if let startDate = points.first?.date {
                Text(Self.dateFormatter.string(from: startDate))
            }
            Spacer(minLength: 8)
            if let endDate = points.last?.date {
                Text(Self.dateFormatter.string(from: endDate))
            }
        }
        .padding(.horizontal, plotHorizontalPadding)
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(MaxwinTheme.cream.opacity(0.8))
    }

    private func yPosition(
        for value: Double,
        domainMin: Double,
        domainSpan: Double,
        plotTop: CGFloat,
        plotHeight: CGFloat
    ) -> CGFloat {
        let normalized = (value - domainMin) / domainSpan
        return plotTop + plotHeight * (1 - CGFloat(normalized))
    }

    private func drawGuideLine(
        at y: CGFloat,
        fromX: CGFloat,
        width: CGFloat,
        opacity: Double,
        in context: inout GraphicsContext
    ) {
        var path = Path()
        path.move(to: CGPoint(x: fromX, y: y))
        path.addLine(to: CGPoint(x: fromX + width, y: y))
        context.stroke(
            path,
            with: .color(MaxwinTheme.cream.opacity(opacity)),
            style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
        )
    }

    private enum LabelHorizontalAlignment {
        case leading, center, trailing
    }

    private func drawPointMarker(
        at point: CGPoint,
        value: Double,
        plotTop: CGFloat,
        plotBottom: CGFloat,
        horizontalAnchor: LabelHorizontalAlignment,
        in context: inout GraphicsContext
    ) {
        let color = value >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed
        let r = pointDotRadius
        let dot = Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))
        context.fill(dot, with: .color(color))

        let resolved = context.resolve(
            Text(CurrencyFormatting.signedString(from: value))
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundColor(MaxwinTheme.cream.opacity(0.92))
        )

        let labelOffset: CGFloat = 10
        let placeAbove = point.y - labelOffset - 6 >= plotTop
        let labelY = placeAbove ? point.y - labelOffset : point.y + labelOffset

        let anchor: UnitPoint = {
            switch (horizontalAnchor, placeAbove) {
            case (.leading, true): return .bottomLeading
            case (.leading, false): return .topLeading
            case (.trailing, true): return .bottomTrailing
            case (.trailing, false): return .topTrailing
            case (.center, true): return .bottom
            case (.center, false): return .top
            }
        }()

        context.draw(resolved, at: CGPoint(x: point.x, y: labelY), anchor: anchor)
    }

    private func drawSegment(
        from start: CGPoint,
        to end: CGPoint,
        startValue: Double,
        endValue: Double,
        zeroY: CGFloat,
        in context: inout GraphicsContext
    ) {
        // Split at zero when a segment crosses the baseline so each side gets its color.
        if (startValue >= 0 && endValue >= 0) || (startValue <= 0 && endValue <= 0) {
            stroke(from: start, to: end, color: startValue >= 0 && endValue >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed, in: &context)
            return
        }

        let total = abs(startValue) + abs(endValue)
        guard total > 0 else {
            stroke(from: start, to: end, color: MaxwinTheme.cream.opacity(0.5), in: &context)
            return
        }

        let t = CGFloat(abs(startValue) / total)
        let cross = CGPoint(
            x: start.x + (end.x - start.x) * t,
            y: zeroY
        )

        stroke(
            from: start,
            to: cross,
            color: startValue >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed,
            in: &context
        )
        stroke(
            from: cross,
            to: end,
            color: endValue >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed,
            in: &context
        )
    }

    private func stroke(
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        in context: inout GraphicsContext
    ) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
}

#Preview {
    WinningsChartView(
        points: [
            EarningsDataPoint(id: UUID(), date: .now.addingTimeInterval(-86400 * 4), cumulativeProfit: 120, periodProfit: 120),
            EarningsDataPoint(id: UUID(), date: .now.addingTimeInterval(-86400 * 3), cumulativeProfit: -40, periodProfit: -160),
            EarningsDataPoint(id: UUID(), date: .now.addingTimeInterval(-86400 * 2), cumulativeProfit: 80, periodProfit: 120),
            EarningsDataPoint(id: UUID(), date: .now.addingTimeInterval(-86400), cumulativeProfit: 210, periodProfit: 130)
        ],
        showYAxisLabels: true
    )
    .frame(height: 240)
    .padding(12)
    .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
}

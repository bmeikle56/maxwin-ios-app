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

    private let yAxisWidth: CGFloat = 48
    private let plotVerticalPadding: CGFloat = 8

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let size = proxy.size
                let leadingInset = showYAxisLabels ? yAxisWidth : 0
                let chartWidth = max(size.width - leadingInset, 1)
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
                        : chartWidth / CGFloat(points.count - 1)

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
                        fromX: leadingInset,
                        width: chartWidth,
                        opacity: 0.85,
                        in: &context
                    )

                    if showYAxisLabels {
                        let extremesDiffer = abs(dataMax - dataMin) > 0.000_1

                        if abs(dataMax) > 0.000_1 {
                            let maxY = yForValue(dataMax)
                            drawGuideLine(
                                at: maxY,
                                fromX: leadingInset,
                                width: chartWidth,
                                opacity: 0.55,
                                in: &context
                            )
                            drawYAxisLabel(
                                CurrencyFormatting.signedString(from: dataMax),
                                at: maxY,
                                in: &context
                            )
                        }

                        if abs(dataMin) > 0.000_1, extremesDiffer || abs(dataMax) <= 0.000_1 {
                            let minY = yForValue(dataMin)
                            drawGuideLine(
                                at: minY,
                                fromX: leadingInset,
                                width: chartWidth,
                                opacity: 0.55,
                                in: &context
                            )
                            drawYAxisLabel(
                                CurrencyFormatting.signedString(from: dataMin),
                                at: minY,
                                in: &context
                            )
                        }

                        drawYAxisLabel("$0", at: zeroY, in: &context)
                    }

                    guard points.count >= 2 else {
                        let y = yForValue(values[0])
                        let x = leadingInset + chartWidth / 2
                        let dot = Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
                        context.fill(dot, with: .color(values[0] >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed))
                        return
                    }

                    for index in 0..<(points.count - 1) {
                        let startValue = values[index]
                        let endValue = values[index + 1]
                        let start = CGPoint(
                            x: leadingInset + CGFloat(index) * stepX,
                            y: yForValue(startValue)
                        )
                        let end = CGPoint(
                            x: leadingInset + CGFloat(index + 1) * stepX,
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
            if showYAxisLabels {
                Color.clear.frame(width: yAxisWidth)
            }

            if let startDate = points.first?.date {
                Text(Self.dateFormatter.string(from: startDate))
            }
            Spacer(minLength: 8)
            if let endDate = points.last?.date {
                Text(Self.dateFormatter.string(from: endDate))
            }
        }
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

    private func drawYAxisLabel(
        _ text: String,
        at y: CGFloat,
        in context: inout GraphicsContext
    ) {
        let resolved = context.resolve(
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(MaxwinTheme.cream.opacity(0.9))
        )
        context.draw(
            resolved,
            at: CGPoint(x: yAxisWidth - 4, y: y),
            anchor: .trailing
        )
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
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
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

//
//  WinningsChartView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct WinningsChartView: View, Animatable {
    let points: [EarningsDataPoint]
    /// 0 → 1 line-draw progress; driven by the same animation as the Track metrics.
    var drawProgress: Double = 1

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private let plotVerticalPadding: CGFloat = 16
    private let plotHorizontalPadding: CGFloat = 28
    private let lineWidth: CGFloat = 1.5

    var animatableData: Double {
        get { drawProgress }
        set { drawProgress = newValue }
    }

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
                let progress = max(0, min(1, drawProgress))

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

                    guard points.count >= 2 else { return }

                    var pieces: [StrokePiece] = []
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
                        pieces.append(contentsOf: coloredPieces(
                            from: start,
                            to: end,
                            startValue: startValue,
                            endValue: endValue,
                            zeroY: zeroY
                        ))
                    }

                    drawPieces(pieces, progress: progress, in: &context)
                }
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

    private struct StrokePiece {
        let start: CGPoint
        let end: CGPoint
        let color: Color

        var length: CGFloat {
            hypot(end.x - start.x, end.y - start.y)
        }
    }

    private func coloredPieces(
        from start: CGPoint,
        to end: CGPoint,
        startValue: Double,
        endValue: Double,
        zeroY: CGFloat
    ) -> [StrokePiece] {
        // Split at zero when a segment crosses the baseline so each side gets its color.
        if (startValue >= 0 && endValue >= 0) || (startValue <= 0 && endValue <= 0) {
            let color = startValue >= 0 && endValue >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed
            return [StrokePiece(start: start, end: end, color: color)]
        }

        let total = abs(startValue) + abs(endValue)
        guard total > 0 else {
            return [StrokePiece(start: start, end: end, color: MaxwinTheme.cream.opacity(0.5))]
        }

        let t = CGFloat(abs(startValue) / total)
        let cross = CGPoint(
            x: start.x + (end.x - start.x) * t,
            y: zeroY
        )

        return [
            StrokePiece(
                start: start,
                end: cross,
                color: startValue >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed
            ),
            StrokePiece(
                start: cross,
                end: end,
                color: endValue >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed
            )
        ]
    }

    private func drawPieces(
        _ pieces: [StrokePiece],
        progress: Double,
        in context: inout GraphicsContext
    ) {
        let totalLength = pieces.reduce(CGFloat(0)) { $0 + $1.length }
        guard totalLength > 0 else { return }

        let targetLength = totalLength * CGFloat(progress)
        var drawnLength: CGFloat = 0

        for piece in pieces {
            if drawnLength >= targetLength { break }

            let remaining = targetLength - drawnLength
            if piece.length <= remaining + 0.000_1 {
                stroke(from: piece.start, to: piece.end, color: piece.color, in: &context)
                drawnLength += piece.length
            } else {
                let t = remaining / piece.length
                let partialEnd = CGPoint(
                    x: piece.start.x + (piece.end.x - piece.start.x) * t,
                    y: piece.start.y + (piece.end.y - piece.start.y) * t
                )
                stroke(from: piece.start, to: partialEnd, color: piece.color, in: &context)
                break
            }
        }
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
        drawProgress: 1
    )
    .frame(height: 240)
    .padding(12)
    .background(MaxwinTheme.panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
}

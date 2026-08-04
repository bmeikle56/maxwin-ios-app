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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let size = proxy.size
                Canvas { context, _ in
                    guard points.count >= 1 else { return }

                    let values = points.map(\.cumulativeProfit)
                    let maxAbs = max(values.map(abs).max() ?? 1, 1)
                    let midY = size.height / 2
                    let scaleY = (size.height * 0.42) / maxAbs
                    let stepX = points.count == 1
                        ? 0
                        : size.width / CGFloat(points.count - 1)

                    // Dotted zero line across the horizontal midline.
                    var zeroPath = Path()
                    zeroPath.move(to: CGPoint(x: 0, y: midY))
                    zeroPath.addLine(to: CGPoint(x: size.width, y: midY))
                    context.stroke(
                        zeroPath,
                        with: .color(MaxwinTheme.cream.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                    )

                    guard points.count >= 2 else {
                        let y = midY - CGFloat(values[0]) * scaleY
                        let dot = Path(ellipseIn: CGRect(x: size.width / 2 - 4, y: y - 4, width: 8, height: 8))
                        context.fill(dot, with: .color(values[0] >= 0 ? MaxwinTheme.winGreen : MaxwinTheme.lossRed))
                        return
                    }

                    for index in 0..<(points.count - 1) {
                        let startValue = values[index]
                        let endValue = values[index + 1]
                        let start = CGPoint(
                            x: CGFloat(index) * stepX,
                            y: midY - CGFloat(startValue) * scaleY
                        )
                        let end = CGPoint(
                            x: CGFloat(index + 1) * stepX,
                            y: midY - CGFloat(endValue) * scaleY
                        )

                        drawSegment(
                            from: start,
                            to: end,
                            startValue: startValue,
                            endValue: endValue,
                            midY: midY,
                            in: &context
                        )
                    }
                }
                .animation(animationsEnabled ? .easeInOut(duration: 0.35) : nil, value: points.map(\.id))
            }

            dateAxis
        }
    }

    private var dateAxis: some View {
        HStack {
            if let startDate = points.first?.date {
                Text(Self.dateFormatter.string(from: startDate))
            }
            Spacer()
            if let endDate = points.last?.date {
                Text(Self.dateFormatter.string(from: endDate))
            }
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(MaxwinTheme.cream.opacity(0.8))
    }

    private func drawSegment(
        from start: CGPoint,
        to end: CGPoint,
        startValue: Double,
        endValue: Double,
        midY: CGFloat,
        in context: inout GraphicsContext
    ) {
        // Split at zero when a segment crosses the midline so each side gets its color.
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
            y: midY
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
        ]
    )
    .frame(height: 220)
    .padding()
    .background(MaxwinTheme.feltDeep)
}

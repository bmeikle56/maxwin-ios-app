//
//  MetricAura.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/5/26.
//

import SwiftUI

/// Shared fire / ice heat mapping used by Track metrics and session profit.
enum MetricHeat {
    /// Soft-maps (−∞, ∞) → (−1, 1); `scale` is the characteristic magnitude for strong saturation.
    static func normalized(_ value: Double, scale: Double) -> Double {
        tanh(value / scale)
    }

    /// Ramps from just above zero toward full as value → +∞.
    static func fireIntensity(normalized: Double) -> Double {
        max(0, min(1, normalized))
    }

    /// Ramps from just below zero toward full as value → −∞.
    static func iceIntensity(normalized: Double) -> Double {
        max(0, min(1, -normalized))
    }

    /// −1 → light blue ice, 0 → white, +1 → bright orange-yellow fire (BB/100 style).
    static func signedHeatColor(normalized t: Double) -> Color {
        let clamped = min(max(t, -1), 1)
        let lightBlue = (r: 0.78, g: 0.93, b: 1.0)
        let white = (r: 1.0, g: 1.0, b: 1.0)
        let fire = (r: 1.0, g: 0.62, b: 0.14)

        if clamped <= 0 {
            let u = clamped + 1
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

    /// 0 → ice blue, 0.5 → white, 1 → bright fire orange/red (win-rate style).
    static func rateHeatColor(_ rate: Double) -> Color {
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

struct MetricFireAura: View {
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

                ForEach(0..<4, id: \.self) { index in
                    let phase = Double(index) * 1.73
                    let speed = 0.18 + Double(index % 2) * 0.04
                    let cycle = (t * speed + phase).truncatingRemainder(dividingBy: 1.0)
                    let riseProgress = cycle < 0 ? cycle + 1 : cycle
                    // Stable per-emission pick: ~80% ember, ~20% ash.
                    let emissionID = index &* 10_007 &+ Int(floor(t * speed + phase))
                    let isEmber = (emissionID &* 2_654_435_761) % 100 < 80
                    let particleSize = (isEmber ? 1.1 : 1.35)
                        * (1.0 + CGFloat(index % 2) * 0.25)
                        * max(scaleX, scaleY)
                    let xBase = (CGFloat(index) / 3.0 - 0.5) * width * 0.7
                    let xDrift = CGFloat(sin(t * (1.1 + Double(index) * 0.22) + phase)) * 4 * scaleX
                    let y = (height * 0.42) - CGFloat(riseProgress) * height * 1.05
                    let fade = sin(riseProgress * .pi)

                    if isEmber {
                        let glow = 0.75 + 0.25 * sin(t * (5 + Double(index)) + phase)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.92, blue: 0.45).opacity(0.9 * intensity * fade * glow),
                                        Color(red: 1.0, green: 0.45, blue: 0.08).opacity(0.65 * intensity * fade),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: particleSize * 1.3
                                )
                            )
                            .frame(width: particleSize * 2, height: particleSize * 2)
                            .offset(x: xBase + xDrift, y: y)
                            .blur(radius: 0.35)
                    } else {
                        Circle()
                            .fill(Color.black.opacity(0.55 * intensity * fade))
                            .frame(width: particleSize * 1.6, height: particleSize * 1.6)
                            .offset(x: xBase + xDrift, y: y)
                            .blur(radius: 0.25)
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

struct MetricIceAura: View {
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

                ForEach(0..<7, id: \.self) { index in
                    let phase = Double(index) * 1.37
                    let cycle = (t * (0.35 + Double(index % 3) * 0.08) + phase)
                        .truncatingRemainder(dividingBy: 1.0)
                    let fallProgress = cycle < 0 ? cycle + 1 : cycle
                    let flakeSize = (4.5 + CGFloat(index % 3) * 1.4) * max(scaleX, scaleY) * 0.85
                    let xBase = (CGFloat(index) / 6.0 - 0.5) * width * 0.85
                    let xDrift = CGFloat(sin(t * (1.1 + Double(index) * 0.25) + phase)) * 6 * scaleX
                    let y = (-height * 0.55) + CGFloat(fallProgress) * height * 1.2
                    let fade = sin(fallProgress * .pi)

                    Image(systemName: "snowflake")
                        .font(.system(size: flakeSize, weight: .semibold))
                        .foregroundStyle(
                            Color(red: 0.78, green: 0.92, blue: 1.0)
                                .opacity(0.55 * intensity * fade)
                        )
                        .rotationEffect(.degrees(t * (18 + Double(index) * 7) + phase * 40))
                        .offset(x: xBase + xDrift, y: y)
                        .blur(radius: index % 2 == 0 ? 0.2 : 0.6)
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

/// Session list profit with BB/100-style heat shading and fire/ice aura.
struct SessionProfitText: View {
    var profit: Double
    var animationsEnabled: Bool = true
    /// Dollar magnitude that maps to strong heat (~±scale → near full fire/ice).
    var heatScale: Double = 400

    private var normalized: Double {
        MetricHeat.normalized(profit, scale: heatScale)
    }

    private var fireIntensity: Double {
        MetricHeat.fireIntensity(normalized: normalized)
    }

    private var iceIntensity: Double {
        MetricHeat.iceIntensity(normalized: normalized)
    }

    var body: some View {
        Text(formatted)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(MetricHeat.signedHeatColor(normalized: normalized))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .background {
                if animationsEnabled {
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
    }

    private var formatted: String {
        if abs(profit) < 0.5 { return "0" }
        let rounded = profit.rounded()
        return String(format: "%.0f", rounded)
    }
}

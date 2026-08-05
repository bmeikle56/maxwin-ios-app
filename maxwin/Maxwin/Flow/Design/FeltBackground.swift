//
//  FeltBackground.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/4/26.
//

import SwiftUI

/// Green felt with a suit-symbol wallpaper. Use via `feltScreenBackground()` so it stays behind content.
struct FeltBackground: View {
    var body: some View {
        ZStack {
            MaxwinTheme.felt
            FeltSymbolWallpaper()
        }
        .drawingGroup(opaque: true)
        .ignoresSafeArea(.all)
        .allowsHitTesting(false)
    }
}

extension View {
    /// Places felt + wallpaper behind content, edge-to-edge including under the nav bar.
    func feltScreenBackground() -> some View {
        self
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background {
                FeltBackground()
            }
    }
}

private enum WallpaperSuit: CaseIterable {
    case spade, diamond

    var systemImage: String {
        switch self {
        case .spade: return "suit.spade.fill"
        case .diamond: return "suit.diamond.fill"
        }
    }

    var color: Color {
        switch self {
        case .spade:
            return .black
        case .diamond:
            return Color(red: 0.03, green: 0.08, blue: 0.045)
        }
    }

    /// Checkerboard: diamond, spade, diamond, spade…
    static func suit(row: Int, col: Int) -> WallpaperSuit {
        (row + col).isMultiple(of: 2) ? .diamond : .spade
    }
}

private struct FeltSymbolWallpaper: View {
    private let spacing: CGFloat = 44
    private let symbolSize: CGFloat = 18

    var body: some View {
        GeometryReader { proxy in
            let cols = Int(ceil(proxy.size.width / spacing)) + 2
            let rows = Int(ceil(proxy.size.height / spacing)) + 2

            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<cols, id: \.self) { col in
                    let suit = WallpaperSuit.suit(row: row, col: col)
                    Image(systemName: suit.systemImage)
                        .font(.system(size: symbolSize, weight: .medium))
                        .foregroundStyle(suit.color)
                        .frame(width: spacing, height: spacing)
                        .position(
                            x: CGFloat(col) * spacing + spacing / 2,
                            y: CGFloat(row) * spacing + spacing / 2
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    Text("Content stays on top")
        .foregroundStyle(MaxwinTheme.cream)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltScreenBackground()
}

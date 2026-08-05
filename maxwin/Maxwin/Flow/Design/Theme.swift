//
//  Theme.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

enum MaxwinTheme {
    static let felt = Color(red: 0.015, green: 0.04, blue: 0.025)
    static let feltDeep = Color(red: 0.01, green: 0.028, blue: 0.016)
    static let gold = Color(red: 0.82, green: 0.69, blue: 0.29)
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let mutedCream = Color(red: 0.96, green: 0.94, blue: 0.88).opacity(0.72)
    /// Darker gray for Track summary titles and values.
    static let headerGray = Color(white: 0.55)
    /// Opaque elevated surface so wallpaper does not show through cards.
    static let fieldFill = Color(red: 0.04, green: 0.08, blue: 0.055)
    /// Opaque darker panel used for charts and inset cards.
    static let panelFill = Color(red: 0.012, green: 0.032, blue: 0.02)
    static let fieldStroke = Color.white.opacity(0.16)
    /// Soft green divider that sits quietly on the felt.
    static let divider = Color(red: 0.10, green: 0.22, blue: 0.14)
    static let winGreen = Color(red: 0.35, green: 0.78, blue: 0.48)
    static let lossRed = Color(red: 0.92, green: 0.38, blue: 0.36)
}

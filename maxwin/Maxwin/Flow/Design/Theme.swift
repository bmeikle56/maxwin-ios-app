//
//  Theme.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

enum MaxwinTheme {
    static let felt = Color(red: 0.03, green: 0.07, blue: 0.045)
    static let feltDeep = Color(red: 0.5, green: 0.15, blue: 0.5)
    static let gold = Color(red: 0.82, green: 0.69, blue: 0.29)
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let mutedCream = Color(red: 0.96, green: 0.94, blue: 0.88).opacity(0.72)
    static let fieldFill = Color.white.opacity(0.08)
    static let fieldStroke = Color.white.opacity(0.16)
    static let winGreen = Color(red: 0.35, green: 0.78, blue: 0.48)
    static let lossRed = Color(red: 0.92, green: 0.38, blue: 0.36)
}

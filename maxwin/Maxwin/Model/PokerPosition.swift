//
//  PokerPosition.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/4/26.
//

import Foundation

enum PokerPosition: String, CaseIterable, Identifiable, Sendable {
    case utg = "UTG"
    case utgPlus1 = "UTG+1"
    case utgPlus2 = "UTG+2"
    case mp = "MP"
    case lj = "LJ"
    case hj = "HJ"
    case co = "CO"
    case btn = "BTN"
    case sb = "SB"
    case bb = "BB"

    var id: String { rawValue }
}

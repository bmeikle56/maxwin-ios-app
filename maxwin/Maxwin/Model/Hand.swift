//
//  Hand.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

struct Hand: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let handNumber: Int
    let position: String
    let holeCards: String
    let result: Double
    let notes: String?
    /// Street-by-street / board breakdown. Explicitly optional — sessions and APIs may omit it.
    let detail: HandDetail?
}

struct HandDetail: Equatable, Codable, Sendable {
    var board: String?
    var potSize: Double?
    var opponents: Int?
    var villainHand: String?
    var allInStreet: String?
    var streets: [StreetAction]?

    var hasContent: Bool {
        let hasBoard = !(board?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasVillain = !(villainHand?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasAllIn = !(allInStreet?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasStreets = !(streets?.isEmpty ?? true)
        return hasBoard || potSize != nil || opponents != nil || hasVillain || hasAllIn || hasStreets
    }
}

struct StreetAction: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let street: String
    let action: String
    let potAfter: Double?
}

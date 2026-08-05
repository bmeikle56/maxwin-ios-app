//
//  SessionDraft.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

struct SessionDraft: Equatable {
    var id: UUID?
    var date: Date
    var venue: String
    var gameType: GameType
    var stakes: String
    var durationMinutes: Int
    var buyIn: Double
    var cashOut: Double
    var hands: [HandDraft]
    var isFavorite: Bool

    var isEditing: Bool { id != nil }

    static func blank(date: Date = .now) -> SessionDraft {
        SessionDraft(
            id: nil,
            date: date,
            venue: "",
            gameType: .cash,
            stakes: "",
            durationMinutes: 120,
            buyIn: 0,
            cashOut: 0,
            hands: [],
            isFavorite: false
        )
    }

    init(session: PokerSession) {
        id = session.id
        date = session.date
        venue = session.venue
        gameType = session.gameType
        stakes = session.stakes
        durationMinutes = session.durationMinutes
        buyIn = session.buyIn
        cashOut = session.cashOut
        hands = session.hands.map(HandDraft.init(hand:))
        isFavorite = session.isFavorite
    }

    init(
        id: UUID?,
        date: Date,
        venue: String,
        gameType: GameType,
        stakes: String,
        durationMinutes: Int,
        buyIn: Double,
        cashOut: Double,
        hands: [HandDraft],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.date = date
        self.venue = venue
        self.gameType = gameType
        self.stakes = stakes
        self.durationMinutes = durationMinutes
        self.buyIn = buyIn
        self.cashOut = cashOut
        self.hands = hands
        self.isFavorite = isFavorite
    }

    func makeSession() -> PokerSession {
        PokerSession(
            id: id ?? UUID(),
            date: date,
            venue: venue.trimmingCharacters(in: .whitespacesAndNewlines),
            gameType: gameType,
            stakes: stakes.trimmingCharacters(in: .whitespacesAndNewlines),
            durationMinutes: max(durationMinutes, 0),
            buyIn: buyIn,
            cashOut: cashOut,
            hands: hands.enumerated().map { index, draft in
                draft.makeHand(fallbackNumber: index + 1)
            },
            isFavorite: isFavorite
        )
    }
}

struct HandDraft: Identifiable, Equatable {
    var id: UUID
    var handNumber: Int
    var position: String
    var holeCards: String
    var result: Double
    var notes: String
    /// When false, `detail` is omitted from the saved hand.
    var includeDetail: Bool
    var board: String
    var potSize: Double?
    var opponents: Int?
    var villainHand: String
    var allInStreet: String
    var streetsText: String

    static func blank(handNumber: Int) -> HandDraft {
        HandDraft(
            id: UUID(),
            handNumber: handNumber,
            position: "BTN",
            holeCards: "",
            result: 0,
            notes: "",
            includeDetail: false,
            board: "",
            potSize: nil,
            opponents: nil,
            villainHand: "",
            allInStreet: "",
            streetsText: ""
        )
    }

    init(hand: Hand) {
        id = hand.id
        handNumber = hand.handNumber
        position = hand.position
        holeCards = hand.holeCards
        result = hand.result
        notes = hand.notes ?? ""
        includeDetail = hand.detail != nil
        board = hand.detail?.board ?? ""
        potSize = hand.detail?.potSize
        opponents = hand.detail?.opponents
        villainHand = hand.detail?.villainHand ?? ""
        allInStreet = hand.detail?.allInStreet ?? ""
        streetsText = (hand.detail?.streets ?? [])
            .map { street in
                if let pot = street.potAfter {
                    return "\(street.street): \(street.action) (pot \(Int(pot)))"
                }
                return "\(street.street): \(street.action)"
            }
            .joined(separator: "\n")
    }

    init(
        id: UUID,
        handNumber: Int,
        position: String,
        holeCards: String,
        result: Double,
        notes: String,
        includeDetail: Bool,
        board: String,
        potSize: Double?,
        opponents: Int?,
        villainHand: String,
        allInStreet: String,
        streetsText: String
    ) {
        self.id = id
        self.handNumber = handNumber
        self.position = position
        self.holeCards = holeCards
        self.result = result
        self.notes = notes
        self.includeDetail = includeDetail
        self.board = board
        self.potSize = potSize
        self.opponents = opponents
        self.villainHand = villainHand
        self.allInStreet = allInStreet
        self.streetsText = streetsText
    }

    func makeHand(fallbackNumber: Int) -> Hand {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return Hand(
            id: id,
            handNumber: handNumber > 0 ? handNumber : fallbackNumber,
            position: position.trimmingCharacters(in: .whitespacesAndNewlines),
            holeCards: holeCards.trimmingCharacters(in: .whitespacesAndNewlines),
            result: result,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            detail: includeDetail ? makeOptionalDetail() : nil
        )
    }

    /// Builds detail only when the user opted in and at least one field has content.
    private func makeOptionalDetail() -> HandDetail? {
        let streets = parseStreets()
        let detail = HandDetail(
            board: blankToNil(board),
            potSize: potSize,
            opponents: opponents,
            villainHand: blankToNil(villainHand),
            allInStreet: blankToNil(allInStreet),
            streets: streets.isEmpty ? nil : streets
        )
        return detail.hasContent ? detail : nil
    }

    private func parseStreets() -> [StreetAction] {
        streetsText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                let parts = line.split(separator: ":", maxSplits: 1).map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if parts.count == 2 {
                    return StreetAction(id: UUID(), street: parts[0], action: parts[1], potAfter: nil)
                }
                return StreetAction(id: UUID(), street: "Action", action: line, potAfter: nil)
            }
    }

    private func blankToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

//
//  CurrencyFormatting.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import Foundation

enum CurrencyFormatting {
    private static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let signedCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        formatter.positivePrefix = "+"
        return formatter
    }()

    static func string(from value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "$0"
    }

    static func signedString(from value: Double) -> String {
        if value == 0 { return "$0" }
        return signedCurrency.string(from: NSNumber(value: value)) ?? "$0"
    }
}

//
//  MaxPrecisionNumber+Helpers.swift
//  Calculator
//
//  Created by Alexander Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

enum MaxDisplayLength: Int {
    case buttonDisplay = 8
    case fullDisplay = 12
    case highestLimit = 20
}

extension MaxPrecisionNumber {
    func isWhole() -> Bool {
        return self.remainder(dividingBy: 1) == 0 || self.isInfinite
    }
    
    func isEven() -> Bool {
        return self.truncatingRemainder(dividingBy: 2.0) == 0
    }
    
    func getSign() -> MaxPrecisionNumber {
        return self >= 0 ? 1.0 : -1.0
    }
    
    // Forces the displayed number to be the appropriate character length depending on the display type
    func toSimpleNumericString(for displayLimit: MaxDisplayLength = .highestLimit) -> String {
        guard !self.isNaN else {
            return String("NaN")
        }
        
        var value = String(self).removeFirstContainedSuffix([".0", "E0", "e0"])
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.maximumSignificantDigits = displayLimit.rawValue
        
        if value.count > displayLimit.rawValue && (displayLimit == .buttonDisplay || self.remainder(dividingBy: 1) == 0) {
            var formattedValue = formatter.string(from: NSNumber(value: Double(self))) ?? "NaN"
            
            if formattedValue.count > displayLimit.rawValue {
                let eLength = max(formattedValue.distance(from: (formattedValue.firstIndex(where: {["E", "e"].contains($0)}) ?? formattedValue.endIndex), to: formattedValue.endIndex), 0)
                formatter.maximumSignificantDigits = displayLimit.rawValue - formattedValue.countCharacters(["-", "."], until: ["E", "e"]) - eLength
                formattedValue = formatter.string(from: NSNumber(value: Double(self))) ?? "NaN"
            }
            
            value = formattedValue
        }
        
        if ("+∞" == value) {
            return "inf"
        } else if ("-∞" == value) {
            return "-inf"
        }
        
        return value.removeFirstContainedSuffix([".0", "E0", "e0"])
    }
}

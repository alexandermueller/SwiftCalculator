//
//  Double+ToSimpleNumericString.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

enum MaxDisplayLength: Int {
    case buttonDisplay = 8
    case fullDisplay = 12
    case highestLimit = 20
}

extension Double {
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
            var formattedValue = formatter.string(from: NSNumber(value: self)) ?? "NaN"
            
            if formattedValue.count > displayLimit.rawValue {
                let eLength = max(formattedValue.distance(from: (formattedValue.firstIndex(where: {["E", "e"].contains($0)}) ?? formattedValue.endIndex), to: formattedValue.endIndex), 0)
                formatter.maximumSignificantDigits = displayLimit.rawValue - formattedValue.countCharacters(["-", "."], until: ["E", "e"]) - eLength
                formattedValue = formatter.string(from: NSNumber(value: self)) ?? "NaN"
            }
            
            value = formattedValue
        }
        
        return value.removeFirstContainedSuffix([".0", "E0", "e0"])
    }
}

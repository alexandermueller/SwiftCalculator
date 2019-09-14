//
//  Double+toSimpleNumericString.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

let kMaxDisplayLength = 8
let kMaxSignificantDigits = 3

extension Double {
    func toSimpleNumericString() -> String {
        guard !self.isNaN else {
            return String("NaN")
        }

        let stringValue = String(self)
        let formatter = NumberFormatter()
        formatter.numberStyle = .scientific
        formatter.maximumSignificantDigits = kMaxSignificantDigits
        
        if stringValue.count > kMaxDisplayLength {
            return formatter.string(from: NSNumber(value:self)) ?? "NaN"
        } else if self.remainder(dividingBy: 1) == 0 {
            let endOfIntegerValue = stringValue.firstIndex(of: ".") ?? stringValue.endIndex
            return String(stringValue[..<endOfIntegerValue])
        }
        
        return String(self)
    }
}

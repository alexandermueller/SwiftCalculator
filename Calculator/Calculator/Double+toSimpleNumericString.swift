//
//  Double+toSimpleNumericString.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

extension Double {
    func toSimpleNumericString() -> String {
        guard !self.isNaN else {
            return String("NaN")
        }

        let stringValue = String(self)
        
        if stringValue.contains("e") {
            return stringValue
        } else if self.remainder(dividingBy: 1) == 0 {
            let endOfIntegerValue = stringValue.firstIndex(of: ".") ?? stringValue.endIndex
            
            print(String(self))
            print(stringValue)
            
            return String(stringValue[..<endOfIntegerValue])
        }
        
        return String(self)
    }
}

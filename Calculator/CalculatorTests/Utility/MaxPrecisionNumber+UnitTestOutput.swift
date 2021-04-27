//
//  MaxPrecisionNumber+isNaN.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension MaxPrecisionNumber : UnitTestOutput {
    func isNaN() -> Bool {
        return self.isNaN
    }
    
    func isEmpty() -> Bool {
        return false
    }
    
    func isPositive() -> Bool {
        return 0 <= self
    }
    
    static func |-| (lhs: MaxPrecisionNumber, rhs: MaxPrecisionNumber) -> MaxPrecisionNumber {
        return abs((lhs - rhs) / lhs)
    }
}

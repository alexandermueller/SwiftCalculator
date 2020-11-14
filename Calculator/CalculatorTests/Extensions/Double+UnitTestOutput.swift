//
//  Double+isNaN.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension Double : UnitTestOutput {
    func isNaN() -> Bool {
        return self.isNaN
    }
    
    func isPositive() -> Bool {
        return 0 <= self
    }
    
    static func |-| (lhs: Double, rhs: Double) -> Double {
        return abs((lhs - rhs) / lhs)
    }
}

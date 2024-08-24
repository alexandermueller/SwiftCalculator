//
//  MaxPrecisionNumber+UnitTestOutput.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

private let kErrorThreshold: MaxPrecisionNumber = 1 * powl(10, -18)

extension MaxPrecisionNumber: UnitTestOutput {
    static func ≈≈ (lhs: MaxPrecisionNumber, rhs: MaxPrecisionNumber) -> Bool {
        guard lhs != rhs else {
            return true
        }

        return lhs.isNaN && rhs.isNaN || abs((lhs - rhs) / lhs) <= kErrorThreshold
    }
    
    func isNaN() -> Bool { self.isNaN }
    func isEmpty() -> Bool { false }
    func isPositive() -> Bool { 0 <= self }
}

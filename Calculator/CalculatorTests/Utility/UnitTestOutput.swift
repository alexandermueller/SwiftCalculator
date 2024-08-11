//
//  UnitTestOutput.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

infix operator ≈≈

protocol UnitTestOutput: Equatable {
    static func ≈≈ (lhs: Self, rhs: Self) -> Bool
    static func <= (lhs: Self, rhs: MaxPrecisionNumber) -> Bool
    
    func isNaN() -> Bool
    func isEmpty() -> Bool
    func isPositive() -> Bool
}

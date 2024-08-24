//
//  String+UnitTestOutput.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension String: UnitTestOutput {
    static func ≈≈ (lhs: String, rhs: String) -> Bool { false }
    static func <= (lhs: String, rhs: MaxPrecisionNumber) -> Bool { false }

    func isNaN() -> Bool { false }
    func isEmpty() -> Bool { self == "" }
    func isPositive() -> Bool { false }
}

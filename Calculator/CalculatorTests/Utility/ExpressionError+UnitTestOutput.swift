//
//  ExpressionError+UnitTestOutput.swift
//  Swift CalculatorTests
//
//  Created by Alexander Mueller on 10.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
@testable import Swift_Calculator

extension ArithmeticExpression.ExpressionError: UnitTestOutput {
    static func ≈≈ (lhs: ArithmeticExpression.ExpressionError, rhs: ArithmeticExpression.ExpressionError) -> Bool {
        guard lhs != rhs else {
            return true
        }

        switch (lhs, rhs) {
        case (.nan, .nan):
            return true
        default:
            return false
        }
    }

    static func <= (lhs: ArithmeticExpression.ExpressionError, rhs: MaxPrecisionNumber) -> Bool { false }

    func isNaN() -> Bool { false }
    func isEmpty() -> Bool { false }
    func isPositive() -> Bool { false }
}

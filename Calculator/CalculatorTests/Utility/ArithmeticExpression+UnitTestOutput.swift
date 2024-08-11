//
//  ArithmeticExpression+UnitTestOutput.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
@testable import Swift_Calculator

extension ArithmeticExpression: UnitTestOutput {
    static func ≈≈ (lhs: ArithmeticExpression, rhs: ArithmeticExpression) -> Bool { false }
    static func <= (lhs: Swift_Calculator.ArithmeticExpression, rhs: MaxPrecisionNumber) -> Bool { false }

    func isNaN() -> Bool {
        switch self {
        case .error:
            true
        default:
            false
        }
    }

    func isEmpty() -> Bool { self == .empty }
    func isPositive() -> Bool { false }
}

//
//  ExpressionState+UnitTestOutput.swift
//  Swift CalculatorTests
//
//  Created by Alexander Mueller on 01.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
@testable import Swift_Calculator

extension CalculatorViewModel.ExpressionState: UnitTestOutput {
    func isNaN() -> Bool {
        false
    }

    func isEmpty() -> Bool {
        false
    }

    func isPositive() -> Bool {
        false
    }

    static func |-| (
        lhs: Swift_Calculator.CalculatorViewModel.ExpressionState,
        rhs: Swift_Calculator.CalculatorViewModel.ExpressionState
    ) -> Swift_Calculator.CalculatorViewModel.ExpressionState {
        .zero
    }

    static func <= (lhs: Swift_Calculator.CalculatorViewModel.ExpressionState, rhs: MaxPrecisionNumber) -> Bool {
        false
    }
}

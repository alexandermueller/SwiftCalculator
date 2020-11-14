//
//  ArithmeticExpression+ImplementsIsNaN.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
@testable import Calculator

extension ArithmeticExpression : UnitTestOutput {
    func isNaN() -> Bool {
        return false
    }
    
    func isPositive() -> Bool {
        return false
    }
    
    static func |-| (lhs: ArithmeticExpression, rhs: ArithmeticExpression) -> ArithmeticExpression {
        return .error
    }
    
    static func <= (lhs: ArithmeticExpression, rhs: Double) -> Bool {
        return false
    }
}

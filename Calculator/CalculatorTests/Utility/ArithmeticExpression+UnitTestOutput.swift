//
//  ArithmeticExpression+ImplementsIsNaN.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
@testable import Swift_Calculator

extension ArithmeticExpression : UnitTestOutput {
    func isNaN() -> Bool {
        return self == .error
    }
    
    func isEmpty() -> Bool {
        return self == .empty
    }
    
    func isPositive() -> Bool {
        return false
    }
    
    static func |-| (lhs: ArithmeticExpression, rhs: ArithmeticExpression) -> ArithmeticExpression {
        return .error
    }
    
    static func <= (lhs: ArithmeticExpression, rhs: MaxPrecisionNumber) -> Bool {
        return false
    }
}

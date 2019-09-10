//
//  ArithmeticExpression.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

indirect enum ArithmeticExpression {
    case number(Double)
    case addition(ArithmeticExpression, ArithmeticExpression)
    case subtraction(ArithmeticExpression, ArithmeticExpression)
    case multiplication(ArithmeticExpression, ArithmeticExpression)
    case division(ArithmeticExpression, ArithmeticExpression)
    case exponentiation(ArithmeticExpression, ArithmeticExpression)
    case parentheses(ArithmeticExpression)
    case error
    
    func evaluate() -> Double {
        switch self {
        case let .number(value):
            return value
        case let .addition(left, right):
            return left.evaluate() + right.evaluate()
        case let .subtraction(left, right):
            return left.evaluate() - right.evaluate()
        case let .multiplication(left, right):
            return left.evaluate() * right.evaluate()
        case let .division(left, right):
            return left.evaluate() / right.evaluate()
        case let .exponentiation(left, right):
            return pow(left.evaluate(), right.evaluate())
        case let .parentheses(expression):
            return expression.evaluate()
        case .error:
            return Double.nan
        }
    }
}

func parseExpression(_ expressionList: [String]) -> ArithmeticExpression {
    //        var pieces: [String] = expression.components(separatedBy: " ")
    //
    //        while pieces.count > 0 {
    //
    //        }
    return .number(0)
}

//
//  ArithmeticExpression.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift

indirect enum ArithmeticExpression: Equatable {
    case number(Double)
    case negation(ArithmeticExpression)
    case squareRoot(ArithmeticExpression)
    case inverse(ArithmeticExpression)
    case absoluteValue(ArithmeticExpression)
    case summation(ArithmeticExpression)
    case addition(ArithmeticExpression, ArithmeticExpression)
    case subtraction(ArithmeticExpression, ArithmeticExpression)
    case modulo(ArithmeticExpression, ArithmeticExpression)
    case multiplication(ArithmeticExpression, ArithmeticExpression)
    case division(ArithmeticExpression, ArithmeticExpression)
    case exponentiation(ArithmeticExpression, ArithmeticExpression)
    case root(ArithmeticExpression, ArithmeticExpression)
    case square(ArithmeticExpression)
    case factorial(ArithmeticExpression)
    case empty
    case error
    
    static func from(function: Function, leftValue: ArithmeticExpression = .empty, rightValue: ArithmeticExpression = .empty) -> ArithmeticExpression {
        switch function {
        case .left(let leftHandFunction):
            switch leftHandFunction {
            case .negate:
                return .negation(rightValue)
            case .sqrt:
                return .squareRoot(rightValue)
            case .inv:
                return .inverse(rightValue)
            case .abs:
                return .absoluteValue(rightValue)
            case .sum:
                return .summation(rightValue)
            }
        case .middle(let middleFunction):
            switch middleFunction {
            case .add:
                return .addition(leftValue, rightValue)
            case .subtract:
                return .subtraction(leftValue, rightValue)
            case .modulo:
                return .modulo(leftValue, rightValue)
            case .multiply:
                return .multiplication(leftValue, rightValue)
            case .divide:
                return .division(leftValue, rightValue)
            case .exponent:
                return .exponentiation(leftValue, rightValue)
            case .root:
                return .root(leftValue, rightValue)
            }
        case .right(let rightHandFunction):
            switch rightHandFunction {
            case .square:
                return .square(leftValue)
            case .factorial:
                return .factorial(leftValue)
            }
        }
    }
    
    // Note: The switch statement in here is buggy and does not catch new enum values!!!!!
    func evaluate() -> Double {
        switch self {
        case .number(let value):
            return value
        case .negation(let value):
            return -value.evaluate()
        case .squareRoot(let base):
            return sqrt(base.evaluate())
        case .inverse(let expression):
            return ArithmeticExpression.division(ArithmeticExpression.number(1), expression).evaluate()
        case .absoluteValue(let expression):
            return abs(expression.evaluate())
        case .summation(let expression):
            let value = expression.evaluate()
            let sign = value / abs(value)
            
            return value.isInt() ? (sign * (abs(value) + 1) * abs(value)) / 2 : .nan
        case .addition(let left, let right):
            return left.evaluate() + right.evaluate()
        case .subtraction(let left, let right):
            return left.evaluate() - right.evaluate()
        case .modulo(let left, let right):
            return left.evaluate().truncatingRemainder(dividingBy: right.evaluate())
        case .multiplication(let left, let right):
            return left.evaluate() * right.evaluate()
        case .division(let left, let right):
            return left.evaluate() / right.evaluate()
        case .exponentiation(let base, let exponent):
            let exponentValue = exponent.evaluate()
            return exponentValue.isNaN ? exponentValue : pow(base.evaluate(), exponentValue)
        case .root(let root, let base):
            let rootValue = root.evaluate()
            return rootValue.isNaN ? rootValue : pow(base.evaluate(), 1 / rootValue)
        case .square(let base):
            return ArithmeticExpression.exponentiation(base, .number(2)).evaluate()
        case .factorial(let expression):
            let value = expression.evaluate()
            
            if value.isInt() {
                let int = Int(value)
                var result: Double = 1
                
                for i in 1 ... max(int, 1) {
                    result *= Double(i)
                }
                
                return result
            }
            
            return .nan
        case .empty, .error:
            return .nan
        }
    }
}

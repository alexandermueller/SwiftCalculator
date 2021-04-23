//
//  ArithmeticExpression.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift

indirect enum ArithmeticExpression : Equatable {
    case number(MaxPrecisionNumber)
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
    
    func evaluate() -> MaxPrecisionNumber {
        switch self {
        case .number(let value):
            return value
        case .negation(let value):
            return -value.evaluate()
        case .squareRoot(let base):
            return sqrt(base.evaluate())
        case .inverse(let expression):
            return ArithmeticExpression.division(ArithmeticExpression.number(1.0), expression).evaluate()
        case .absoluteValue(let expression):
            return abs(expression.evaluate())
        case .summation(let expression):
            let value = expression.evaluate()
            return value.isWhole() ? (value.getSign() * (abs(value) + 1.0) * abs(value)) / 2.0 : .nan
        case .addition(let left, let right):
            return left.evaluate() + right.evaluate()
        case .subtraction(let left, let right):
            return left.evaluate() - right.evaluate()
        case .modulo(let left, let right):
            let leftValue = left.evaluate()
            let rightValue = right.evaluate()
            let remainder = left.evaluate().truncatingRemainder(dividingBy: right.evaluate())
            
            return leftValue.sign != rightValue.sign ? rightValue + remainder : remainder
        case .multiplication(let left, let right):
            return left.evaluate() * right.evaluate()
        case .division(let left, let right):
            return left.evaluate() / right.evaluate()
        case .exponentiation(let base, let exponent):
            let baseValue = base.evaluate()
            let exponentValue = exponent.evaluate()
            guard !baseValue.isNaN && !exponentValue.isNaN else {
                return .nan
            }
            
            let sign = ((1 / exponentValue).isWhole() && !(1 / exponentValue).isEven()) ? base.evaluate().getSign() : 1
            return sign * pow(sign * base.evaluate(), exponentValue)
        case .root(let root, let base):
            return ArithmeticExpression.exponentiation(base, .inverse(root)).evaluate()
        case .square(let base):
            return ArithmeticExpression.exponentiation(base, .number(2.0)).evaluate()
        case .factorial(let expression):
            let value = expression.evaluate()
            guard abs(value) < MaxPrecisionNumber(Int.max) else {
                return value.getSign() * .infinity
            }
            
            if value.isWhole() {
                var result: MaxPrecisionNumber = 1
                let intValue = Int(value)
                let sign = intValue < 0 ? -1 : 1
                let upper = sign * max(abs(sign < 0 ? sign : intValue), 1)
                let lower = sign < 0 ? intValue : sign
                
                for i in lower ... upper {
                    result *= MaxPrecisionNumber(i)
                }
                
                return result
            }
            
            return .nan
        case .empty, .error:
            return .nan
        }
    }
}

//
//  ArithmeticExpression.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

indirect enum ArithmeticExpression: Equatable {
    enum ExpressionError: Error, Equatable {
        case nan(String)
        case invalidExpression
        case thresholdExceeded

        static var decimalPrecisionLoss: Self { .nan("Number has too many digits to express decimal places.") }
        static var incompleteExpression: Self { .nan("Expression is incomplete.") }
        static var undefinedExponentiation: Self { .nan("Exponentiation could not be evaluated.") }
        static var undefinedFactorial: Self { .nan("Factorial is only defined for whole numbers.") }
        static var undefinedSummation: Self { .nan("Summation is only defined for whole numbers.") }
    }

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
    case error(ExpressionError)

    func evaluate() throws -> MaxPrecisionNumber {
        switch self {
        case .number(let value):
            return value
        case .negation(let value):
            return try -value.evaluate()
        case .squareRoot(let base):
            return try sqrt(base.evaluate())
        case .inverse(let expression):
            return try ArithmeticExpression.division(ArithmeticExpression.number(1.0), expression).evaluate()
        case .absoluteValue(let expression):
            return try abs(expression.evaluate())
        case .summation(let expression):
            let value = try expression.evaluate()

            guard value.isWhole() else {
                throw ExpressionError.undefinedSummation
            }

            return (value.getSign() * (abs(value) + 1.0) * abs(value)) / 2.0
        case .addition(let left, let right):
            return try left.evaluate() + right.evaluate()
        case .subtraction(let left, let right):
            return try left.evaluate() - right.evaluate()
        case .modulo(let left, let right):
            let leftValue = try left.evaluate()
            let rightValue = try right.evaluate()
            let remainder = leftValue.truncatingRemainder(dividingBy: rightValue)

            return leftValue.sign != rightValue.sign ? rightValue + remainder : remainder
        case .multiplication(let left, let right):
            return try left.evaluate() * right.evaluate()
        case .division(let left, let right):
            return try left.evaluate() / right.evaluate()
        case .exponentiation(let base, let exponent):
            let baseValue = try base.evaluate()
            let exponentValue = try exponent.evaluate()

            guard !baseValue.isNaN && !exponentValue.isNaN else {
                throw ExpressionError.undefinedExponentiation
            }

            let sign = ((1 / exponentValue).isWhole() && !(1 / exponentValue).isEven()) ? baseValue.getSign() : 1
            return sign * pow(sign * baseValue, exponentValue)
        case .root(let root, let base):
            return try ArithmeticExpression.exponentiation(base, .inverse(root)).evaluate()
        case .square(let base):
            return try ArithmeticExpression.exponentiation(base, .number(2)).evaluate()
        case .factorial(let expression):
            let value = try expression.evaluate()

            // TODO: isWhole is basically useless if the value is so great that the precision loses the decimal places
            guard !value.isNaN && value.isWhole() else {
                throw ExpressionError.undefinedFactorial
            }

            guard abs(value) < MaxPrecisionNumber(Int.max) else {
                return value.getSign() * .infinity
            }

            var result: MaxPrecisionNumber = 1
            let intValue = Int(value)
            let sign = intValue < 0 ? -1 : 1
            let upper = sign * max(abs(sign < 0 ? sign : intValue), 1)
            let lower = sign < 0 ? intValue : sign

            for i in lower ... upper {
                if result.isInfinite {
                    break
                }

                result *= MaxPrecisionNumber(i)
            }

            return result
        case .empty:
            throw ExpressionError.incompleteExpression
        case .error(let error):
            throw error
        }
    }
    
    static func from(
        function: Function,
        leftValue: ArithmeticExpression = .empty,
        rightValue: ArithmeticExpression = .empty
    ) -> ArithmeticExpression {
        switch function {
        case .left(let leftHandFunction):
            switch leftHandFunction {
            case .negate:
                .negation(rightValue)
            case .sqrt:
                .squareRoot(rightValue)
            case .abs:
                .absoluteValue(rightValue)
            case .sum:
                .summation(rightValue)
            }
        case .middle(let middleFunction):
            switch middleFunction {
            case .add:
                .addition(leftValue, rightValue)
            case .subtract:
                .subtraction(leftValue, rightValue)
            case .modulo:
                .modulo(leftValue, rightValue)
            case .multiply:
                .multiplication(leftValue, rightValue)
            case .divide:
                .division(leftValue, rightValue)
            case .exponent:
                .exponentiation(leftValue, rightValue)
            case .root:
                .root(leftValue, rightValue)
            }
        case .right(let rightHandFunction):
            switch rightHandFunction {
            case .factorial:
                .factorial(leftValue)
            }
        }
    }
}

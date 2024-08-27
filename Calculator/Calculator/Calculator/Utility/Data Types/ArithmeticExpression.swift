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
        case invalidExpression
        case nan(String)

        static var decimalPrecisionLoss: Self { .nan("Truncated Decimal") }
        static var incompleteExpression: Self { .nan("Incomplete Expression") }
        static var undefinedExpression: Self { .nan("Undefined Expression") }

        static func undefined(function: Function) -> Self {
            .nan("Undefined \(function.action)")
        }

        static func undefined(from expression: ArithmeticExpression) -> Self? {
            if case ArithmeticExpression.number = expression {
                return nil
            }

            guard let function = expression.toFunction() else {
                return undefinedExpression
            }

            return undefined(function: function)
        }
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

    func evaluate() throws -> MaxPrecisionNumber {
        let result = try {
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
                    return .nan
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
                    return .nan
                }

                let sign = ((1 / exponentValue).isWhole() && !(1 / exponentValue).isEven()) ? baseValue.getSign() : 1
                return sign * pow(sign * baseValue, exponentValue)
            case .root(let root, let base):
                return try ArithmeticExpression.exponentiation(base, .inverse(root)).evaluate()
            case .square(let base):
                return try ArithmeticExpression.exponentiation(base, .number(2)).evaluate()
            case .factorial(let expression):
                let value = try expression.evaluate()

                guard !value.isNaN && value.isWhole() else {
                    return .nan
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
        }()

        if result.isNaN, let error = ExpressionError.undefined(from: self) {
            throw error
        }

        return result
    }

    func toFunction() -> Function? {
        switch self {
        case .negation:
            .left(.negate)
        case .squareRoot:
            .left(.sqrt)
        case .absoluteValue:
            .left(.abs)
        case .summation:
            .left(.sum)
        case .addition:
            .middle(.add)
        case .subtraction:
            .middle(.subtract)
        case .modulo:
            .middle(.modulo)
        case .multiplication:
            .middle(.multiply)
        case .division:
            .middle(.divide)
        case .exponentiation:
            .middle(.exponent)
        case .root:
            .middle(.root)
        case .factorial:
            .right(.factorial)
        case .number, .inverse, .square, .empty, .error:
            nil
        }
    }
}

private extension Function {
    var action: String {
        switch self {
        case .left(let left):
            switch left {
            case .negate:
                "Negation"
            case .sqrt:
                "Square Root"
            case .abs:
                "Absolute Value"
            case .sum:
                "Summation"
            }
        case .middle(let middle):
            switch middle {
            case .add:
                "Addition"
            case .subtract:
                "Subtraction"
            case .modulo:
                "Modulus"
            case .multiply:
                "Multiplication"
            case .divide:
                "Division"
            case .exponent:
                "Exponentiation"
            case .root:
                "Root"
            }
        case .right(let right):
            switch right {
            case .factorial:
                "Factorial"
            }
        }
    }
}

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
                return .negation(leftValue)
            case .sqrt:
                return .squareRoot(leftValue)
            case .inv:
                return .inverse(leftValue)
            case .abs:
                return .absoluteValue(leftValue)
            case .sum:
                return .summation(leftValue)
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
            
            return value.isInt() ? (sign * (value + 1) * value) / 2 : .nan
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


class Generator {
    private var currentState: GeneratorState = .start
    private var rightValue: ArithmeticExpression = .empty
    private var function: ArithmeticExpression = .empty
    private var leftValue: ArithmeticExpression = .empty
    
    private let elementSubject = PublishSubject<String>()
    private let expressionSubject = PublishSubject<ArithmeticExpression>()
    private var transferFunction = SerialDisposable()
    private let bag = DisposeBag()
    
    enum GeneratorState: Equatable {
        case start
        case rightValue(ArithmeticExpression)
        case parseLeftValue
        case error
    }
    
    // Parse parses from back to front, as this kind of expression generation relies on stack-like traversal.
    func parse(_ elementStack: [String]) -> ArithmeticExpression {
        self.goToStart()
        
        // TODO: This neads to take into account that the state machine is decoupled from the parse function,
        // otherwise the resulting state will not be what we expect and it will return an error
        
//        for element in elementStack {
//            elementSubject.onNext(element)
//
//            if currentState == .error {
//                return .error
//            }
//        }
//
//        switch currentState {
//        case .rightValue(let expression):
//            return expression
//        default:
//            return .error
//        }
        return .error
    }
    
    // MARK: State Machine Functions
    
    private func goToStart() {
        currentState = .start
    }
    
    private func goToRightValue() {
        currentState = .rightValue(rightValue)
    }
    
    private func goToParseLeftValue() {
        currentState = .parseLeftValue
        
        // Accept input until the function significance found is either less than the current/last one, or there are no values left
        let generator = Generator()
    }
    
    private func goToError() {
        currentState = .error
    }
}

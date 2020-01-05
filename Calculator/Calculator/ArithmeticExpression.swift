//
//  ArithmeticExpression.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

typealias ParseUntilResult = (parsedExpression: ArithmeticExpression, expressionStack: [String])

indirect enum ArithmeticExpression: Equatable {
    case number(Double)
    case negation(ArithmeticExpression)
    case squareRoot(ArithmeticExpression)
    case factorial(ArithmeticExpression)
    case addition(ArithmeticExpression, ArithmeticExpression)
    case subtraction(ArithmeticExpression, ArithmeticExpression)
    case multiplication(ArithmeticExpression, ArithmeticExpression)
    case division(ArithmeticExpression, ArithmeticExpression)
    case exponentiation(ArithmeticExpression, ArithmeticExpression)
    case root(ArithmeticExpression, ArithmeticExpression)
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
            }
        case .middle(let middleFunction):
            switch middleFunction {
            case .add:
                return .addition(leftValue, rightValue)
            case .subtract:
                return .subtraction(leftValue, rightValue)
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
            case .factorial:
                return .factorial(leftValue)
            }
        }
    }
    
    func evaluate() -> Double {
        switch self {
        case .number(let value):
                return value
        case .negation(let value):
            return -value.evaluate()
        case .squareRoot(let base):
            return sqrt(base.evaluate())
        case .addition(let left, let right):
            return left.evaluate() + right.evaluate()
        case .subtraction(let left, let right):
            return left.evaluate() - right.evaluate()
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
        case .factorial(let end):
            let endValue = end.evaluate()
            
            if endValue.remainder(dividingBy: 1) == 0 {
                let endInt = Int(endValue)
                var result: Double = 1
                
                for i in 1 ... max(endInt, 1) {
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

// SEE NOTES... Basically approach like a stack (flip the stack first though) and move from rs to ls.

func parseExpression(_ elementStack: [String], untilLessSignificantThan function: Function? = nil) -> ParseUntilResult {
    guard elementStack.count > 0 else {
        return ParseUntilResult(parsedExpression: .empty, expressionStack: [])
    }
    
    var fnc: ArithmeticExpression = .empty
    
    var lval: ArithmeticExpression = .empty
    var rval: ArithmeticExpression = .empty
    var remainingElemetStack: [String] = elementStack
    
    while remainingElemetStack.count > 0 {
        let element: String = remainingElemetStack.removeFirst()
        let potentialFunction = Function.from(rawValue: element)
        
        // This is a function
        if potentialFunction != nil {
            if fnc == .empty {
                fnc = ArithmeticExpression.from(function: potentialFunction!)
                continue
            }
            
            
        }
        
        
    }
    
    if rval == .empty || rval == .error {
        return ParseUntilResult(parsedExpression: rval, expressionStack: [])
    }
    
    return ParseUntilResult(parsedExpression: .empty, expressionStack: [])
}

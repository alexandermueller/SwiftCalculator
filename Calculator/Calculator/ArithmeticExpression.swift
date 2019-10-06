//
//  ArithmeticExpression.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

typealias ParenthesesMappingResult = (processedElementList: [String], mapping: [String : [String]])

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
        case .factorial(let end):
            let endValue = end.evaluate()
            
            if endValue.remainder(dividingBy: 1).isZero && String(endValue).isInt(){
                let endInt = Int(endValue)
                var result = 1
                
                for i in 1 ... max(endInt, 1) {
                    result *= i
                }
                
                return Double(result)
            }
            
            return .nan
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
        case .empty, .error:
            return .nan
        }
    }
}

func mapParentheses(_ elementList: [String], _ oldMapping: [String : [String]] = [:]) -> ParenthesesMappingResult {
    var seen = 0
    var startIndex = 0
    var encapsulated: [String] = []
    var mapping: [String : [String]] = oldMapping
    var processed: [String] = []
    
    for (index, element) in elementList.enumerated() {
        if seen == 0 && element.isOpenParen() {
            startIndex = index
        }
        
        seen += element.isOpenParen() ? 1 : element.isCloseParen() ? -1 : 0
        
        if seen > 0 && startIndex != index {
            encapsulated += [element]
        }
        
        if seen == 0 {
            if element.isCloseParen() {
                let key = "p\(startIndex),\(index),\(mapping.count)"
                mapping[key] = encapsulated
                processed += [key]
                encapsulated = []
                continue
            }
            
            processed += [element]
        }
    }
    
    return seen == 0 ? ParenthesesMappingResult(processedElementList: processed, mapping: mapping) :
                       ParenthesesMappingResult(processedElementList: [], mapping: [:])
}

func parseExpression(_ elementList: [String], _ parenthesesMapping: [String : [String]] = [:]) -> ArithmeticExpression {
    // Need to make a new check? Or let it parse itself to death? IE when it creates an
    // ArithmeticExpression, it defaults to empty, so I'm guessing this will work out to .nan either way?
    
    let (processedElementList, currentMapping) = mapParentheses(elementList, parenthesesMapping)
    
    // Unbalanced parentheses!
    if processedElementList.count == 0 {
        return .error
    } 
    
    var expressionList : [ArithmeticExpression] = []
    
    for element in processedElementList {
        let possibleFunction = Function.from(rawValue: element)
        
        if possibleFunction == nil {
            if let value: [String] = currentMapping[element] {
                let parsedExpression = parseExpression(value, parenthesesMapping)
                
                if parsedExpression == .error {
                    return .error
                }
                
                expressionList += [parsedExpression]
                continue
            } else if element.isProperDouble(), let value: Double = Double(element) {
                expressionList += [.number(value)]
                continue
            }
        }
        
        guard let functionElement = possibleFunction else {
            return .error // The element encountered hasn't been accounted for yet, or isn't a proper Double!!
        }
        
        expressionList += [ArithmeticExpression.from(function: functionElement)]
    }
    
    var expressionStack: [ArithmeticExpression] = []
    var shouldSkip = false
    
    for (function, functionExpression) in Function.allCasesOrdered().map({($0, ArithmeticExpression.from(function: $0))}) {
        for (index, expression) in expressionList.enumerated() {
            if shouldSkip {
                shouldSkip = false
                continue
            }
            
            if expression == functionExpression {
                guard let last = expressionStack.popLast() else {
                    return .error
                }
                
                switch functionExpression {
                case .number(_):
                    return .error
                case .negation(_), .squareRoot(_):
                    guard index + 1 < expressionList.count else {
                        return .error
                    }
                    
                    expressionStack += [last, expressionList[index + 1]]
                    shouldSkip = true
                case .addition(_, _), .subtraction(_, _), .multiplication(_, _), .division(_, _), .exponentiation(_, _), .root(_, _):
                    guard index + 1 < expressionList.count else {
                        return .error
                    }
                    
                    let next = expressionList[index + 1]
                    expressionStack += [ArithmeticExpression.from(function: function, leftValue: last, rightValue: next)]
                    
                    
                    shouldSkip = true
                case .factorial(_):
                    expressionStack += [ArithmeticExpression.from(function: function, leftValue: last)]
                case .empty, .error:
                    return .error
                }
            }
            
            expressionStack += [expression]
        }
        
        expressionList = expressionStack
        expressionStack = []
    }
    
    return expressionList.count == 1 ? expressionList[0] : .error
}

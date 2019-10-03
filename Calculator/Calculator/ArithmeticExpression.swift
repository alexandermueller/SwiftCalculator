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
    case addition(ArithmeticExpression, ArithmeticExpression)
    case subtraction(ArithmeticExpression, ArithmeticExpression)
    case multiplication(ArithmeticExpression, ArithmeticExpression)
    case division(ArithmeticExpression, ArithmeticExpression)
    case exponentiation(ArithmeticExpression, ArithmeticExpression)
    case root(ArithmeticExpression, ArithmeticExpression)
    case empty
    case error
    
    func evaluate() -> Double {
        switch self {
        case let .number(value):
            return value
        case let .negation(expression):
            return -expression.evaluate()
        case let .addition(left, right):
            return left.evaluate() + right.evaluate()
        case let .subtraction(left, right):
            return left.evaluate() - right.evaluate()
        case let .multiplication(left, right):
            return left.evaluate() * right.evaluate()
        case let .division(left, right):
            return left.evaluate() / right.evaluate()
        case let .exponentiation(left, right):
            let rightValue = right.evaluate()
            return rightValue.isNaN ? rightValue : pow(left.evaluate(), rightValue)
        case let .root(right, left):
            let rightValue = right.evaluate()
            return rightValue.isNaN ? rightValue : pow(left.evaluate(), 1 / rightValue)
        case .empty, .error:
            return .nan
        }
    }
}

func mapParentheses(_ elementList: [String], _ oldMapping: [String : [String]] = [:]) -> ParenthesesMappingResult {
    var seen = 0
    var startIndex = 0
    var firstParen = ""
    var encapsulated: [String] = []
    var mapping: [String : [String]] = oldMapping
    var processed: [String] = []
    
    for (index, element) in elementList.enumerated() {
        if seen == 0 && element.contains("(") {
            firstParen = element
            startIndex = index
        }
        
        seen += element.contains("(") ? 1 : element == ")" ? -1 : 0
        
        if seen > 0 && startIndex != index {
            encapsulated += [element]
        }
        
        if seen == 0 {
            if element == ")" {
                let key = "p\(startIndex),\(index),\(mapping.count)"
                mapping[key] = encapsulated
                processed += [(firstParen.contains("-") ? "-" : "") + key]
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
    // Incomplete expression!
    guard elementList.count % 2 == 1 else {
        return .error
    }
    
    let (processedElementList, currentMapping) = mapParentheses(elementList, parenthesesMapping)
    
    // Unbalanced parentheses!
    if processedElementList.count == 0 {
        return .error
    } 
    
    var expressionList : [ArithmeticExpression] = []
    
    for element in processedElementList {
        let possibleFunction = Function(rawValue: element)
        
        if possibleFunction == nil {
            var key = element
            let hasNegation: Bool = key.contains("-")
            
            if hasNegation {
                key.removeFirst(1)
            }
            
            if let value: [String] = currentMapping[key] {
                let parsedExpression = parseExpression(value, parenthesesMapping)
                
                if parsedExpression == .error {
                    return .error
                }
                
                expressionList += [hasNegation ? .negation(parsedExpression) : parsedExpression]
                
                continue
            } else if element.isProperDouble(), let value: Double = Double(element) {
                expressionList += [.number(value)]
                continue
            }
        }
        
        guard let function = possibleFunction else {
            return .error // The element encountered hasn't been accounted for yet, or isn't a proper Double!!
        }
        
        var functionExpression: ArithmeticExpression {
            switch function {
            case .add:
                return .addition(.empty, .empty)
            case .subtract:
                return .subtraction(.empty, .empty)
            case .multiply:
                return .multiplication(.empty, .empty)
            case .divide:
                return .division(.empty, .empty)
            case .exponent:
                return .exponentiation(.empty, .empty)
            case .root:
                return .root(.empty, .empty)
            }
        }
            
        expressionList += [functionExpression]
    }
    
    for function in Function.allCases.reversed() {
        // TODO TOMORROW!!!
    }
    
    return expressionList.count == 1 ? expressionList[0] : .error
}

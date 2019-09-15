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
    case negation(ArithmeticExpression)
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
        case let .negation(expression):
            return -expression.evaluate()
        case .error:
            return Double.nan
        }
    }
}

func mapParentheses(_ expressionList: [String], _ oldMapping: [String : [String]] = [:]) -> (mappedExpressionList: [String], mapping: [String : [String]]) {
    var seen = 0
    var startIndex = 0
    var firstParen = ""
    var encapsulated: [String] = []
    var mapping: [String : [String]] = oldMapping
    var mapped: [String] = []
    
    for (index, expression) in expressionList.enumerated() {
        if seen == 0 && expression.contains("(") {
            firstParen = expression
            startIndex = index
        }
        
        seen += expression.contains("(") ? 1 : expression == ")" ? -1 : 0
        
        if seen > 0 && startIndex != index {
            encapsulated += [expression]
        }
        
        if seen == 0 {
            if expression == ")" {
                let key = "p\(startIndex),\(index),\(mapping.count)"
                mapping[key] = encapsulated
                mapped += [(firstParen.contains("-") ? "-" : "") + key]
                encapsulated = []
                continue
            }
            
            mapped += [expression]
        }
    }
    
    return seen == 0 ? (mappedExpressionList: mapped, mapping: mapping) : (mappedExpressionList: [], mapping: [:])
}

func parseExpression(_ expressionList: [String], _ parenthesesMapping: [String : [String]] = [:]) -> ArithmeticExpression {
    guard expressionList.count > 0 else {
        return .error
    }
    
    let (mappedExpressionsList, currentMapping) = mapParentheses(expressionList, parenthesesMapping)
    
    if mappedExpressionsList.count == 0 {
        return .error
    } else if mappedExpressionsList.count == 1, let expression = mappedExpressionsList.first {
        var key = expression
        let hasNegation: Bool = key.contains(Button.subtract.rawValue)
        
        if hasNegation {
            key.removeFirst(1)
        }
        
        if let value: [String] = currentMapping[key] {
            let parsedExpression = parseExpression(value, parenthesesMapping)
            
            return hasNegation ? .negation(parsedExpression) : parsedExpression
        } else if expression.isProperDouble(), let value: Double = Double(expression) {
            return .number(value)
        }
        
        return .error
    }

    for operation in [Button.subtract, Button.add, Button.multiply, Button.divide, Button.exponent] {
        var arguments = mappedExpressionsList.split(separator: operation.rawValue)
        
        if arguments.count == 1 {
            continue
        }
        
        let leftSide: [String] = Array(arguments.removeFirst())
        var expression: ArithmeticExpression = .error
        
        while arguments.count > 0 {
            let parsedLeftSide: ArithmeticExpression = leftSide == [] ? expression : parseExpression(leftSide, currentMapping)
            let parsedRightSide: ArithmeticExpression = parseExpression(Array(arguments.removeFirst()), currentMapping)
            var parsedExpression: ArithmeticExpression {
                switch operation {
                case .subtract:
                    return .subtraction(parsedLeftSide, parsedRightSide)
                case .add:
                    return .addition(parsedLeftSide, parsedRightSide)
                case .multiply:
                    return .multiplication(parsedLeftSide, parsedRightSide)
                case .divide:
                    return .division(parsedLeftSide, parsedRightSide)
                case .exponent:
                    return .exponentiation(parsedLeftSide, parsedRightSide)
                default:
                    return .error
                }
            }
            
            expression = parsedExpression
        }
        
        return expression
    }
    
    return .error
}

//
//  ViewModel.swift
//  Calculator
//
//  Created by Alex Mueller on 2019-10-03.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

enum ButtonViewMode {
    case normal
    case alternate
}

class ViewModel {
    var buttonViewMode: ButtonViewMode = .normal
    var parenBalance = 0
    var memory: Double = 0
    var answer: Double = 0
    var currentValue: Double = 0
    var expressionList: [String] = ["0"] {
        didSet {
            if expressionList.isEmpty {
                expressionList = ["0"]
            }
            
            currentValue = parseExpression(expressionList.map({
                switch $0 {
                case Variable.memory.rawValue:
                    return String(memory)
                case "-" + Variable.memory.rawValue:
                    return String(-memory)
                case Variable.answer.rawValue:
                    return String(answer)
                case "-" + Variable.answer.rawValue:
                    return String(-answer)
                default:
                    return $0
                }
            })).evaluate()
        }
    }
    
    func buttonPressed(_ button: Button) {
        let buttonText = button.rawValue()
        let expressionCount = expressionList.count
        let lastExpression: String = expressionList[expressionCount - 1]
        
        switch button {
        case .variable(_):
            if lastExpression.isDouble() && !["0", "-0"].contains(lastExpression) {
                return
            }
            
            fallthrough
        case .digit(_):
            if lastExpression.isCloseParen() || lastExpression.isVariable() {
                return
            }
            
            if lastExpression.isDouble() {
                var newExpression: String {
                    switch lastExpression {
                    case "0":
                        return expressionCount == 1 ? buttonText : lastExpression
                    case "-0":
                        return "-" + buttonText
                    default:
                        return lastExpression + buttonText
                    }
                }
                
                expressionList[expressionCount - 1] = newExpression
            } else {
                expressionList += [buttonText]
            }
        case .modifier(let modifier):
            switch modifier {
            case .decimal:
                if lastExpression.isInt() {
                    expressionList[expressionCount - 1] = lastExpression + buttonText
                }
            }
        case .parenthesis(let parenthesis):
            switch parenthesis {
            case .open:
                if lastExpression == "-0" {
                    expressionList[expressionCount - 1] = "-" + buttonText
                    parenBalance += 1
                    return
                } else if expressionList == ["0"] {
                    expressionList = lastExpression == "0" ? [buttonText] : ["-" + buttonText]
                    parenBalance += 1
                    return
                }
                
                if lastExpression.isCloseParen() || lastExpression.isDouble() {
                    return
                }
                
                parenBalance += 1
                expressionList += [buttonText]
            case .close:
                if !lastExpression.isProperDouble() && !lastExpression.isCloseParen() || parenBalance == 0 {
                    return
                }
                
                expressionList += [buttonText]
                parenBalance -= 1
            }
        case .function(let function):
            switch function {
            case .subtract:
                let allowNegationList: [String] = Function.allCases.map({$0.rawValue}) + [Parenthesis.open.rawValue, "-" + Parenthesis.open.rawValue]
                
                if expressionList == ["0"] {
                    expressionList = ["-0"]
                } else if allowNegationList.contains(lastExpression) {
                    expressionList += ["-0"]
                } else if lastExpression.isCloseParen() || lastExpression.isProperDouble() {
                    expressionList += [buttonText]
                }
            case .add, .multiply, .divide, .exponent, .root:
                if lastExpression.isOpenParen() || !lastExpression.isProperDouble() && !lastExpression.isCloseParen() {
                    return
                }
                
                expressionList += [buttonText]
            }
        case .setter(let setter):
            switch setter {
            case .equal:
                expressionList = Array(expressionList) // Allows for value stepping!
                answer = currentValue
            case .set:
                memory = currentValue
            }
        case .other(let other):
            switch other {
            case .alternate:
                buttonViewMode = buttonViewMode == .normal ? .alternate : .normal
            case .delete:
                parenBalance += lastExpression.isCloseParen() ? 1 : lastExpression.isOpenParen() ? -1 : 0
                
                if lastExpression.isProperDouble() {
                    expressionList[expressionCount - 1] = String(lastExpression.dropLast())
                }
                
                // Also catches pesky "" expressions that persist after deleting doubles
                if !expressionList[expressionCount - 1].isProperDouble() {
                    expressionList = expressionList.dropLast()
                }
            case .clear:
                expressionList = []
                parenBalance = 0
            }
        }
    }
}

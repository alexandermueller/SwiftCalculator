//
//  Generator.swift
//  Calculator
//
//  Created by Alex Mueller on 2020-03-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift

typealias GeneratorReturnType = (rightValue: ArithmeticExpression, newElementStack: [String])

class Generator {
    private var rank: Int = .max
    private var rightValue: ArithmeticExpression = .empty
    private var elementStack: [String] = []
    private let bag = DisposeBag()
    
    // MARK: State Machine Functions
    
    func startGenerator(with elementStack: [String], rank: Int = .max) -> GeneratorReturnType {
        self.rank = rank
        self.elementStack = elementStack
        return goToStart()
    }
    
    private func goToStart() -> GeneratorReturnType {
        rightValue = .empty
        
        if let element = elementStack.popLast() {
            if element.isProperDouble() {
                return goToRightValue(with: .number(element.toDouble()))
            }
            
            if let button = Button.from(rawValue: element) {
                switch button {
                case .parenthesis(let parenthesis):
                    if parenthesis == .close {
                        return goToParseParenthesisLeftValue()
                    }
                case .function(let function):
                    switch function {
                    case .right(_):
                        return goToParseLeftValue(with: function)
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
        
        return goToError()
    }
    
    private func goToRightValue(with expression: ArithmeticExpression) -> GeneratorReturnType {
        rightValue = expression
        
        // If the next level returned after seeing a function whose rank was less significant, short circuit the
        // state transfer function so that it doesn't consume the next element yet, but still processes the missed
        // function and transfers to the next appropriate state.
        if let element = elementStack.popLast() {
            if let function = Function.from(rawValue: element) {
                switch function {
                case .left(_):
                    return goToRightValue(with: ArithmeticExpression.from(function: function, leftValue: .empty, rightValue: rightValue))
                case .middle(_):
                    if function.rank() > rank { // > needs to be this way so that anything on the same level or higher will take priority
                        return GeneratorReturnType(rightValue: rightValue, newElementStack: elementStack + [function.rawValue()]) // need to replace the function onto the stack, as should not be consumed
                    }
                    
                    return goToParseLeftValue(with: function)
                default:
                    return goToError()
                }
            }
        }
        
        return GeneratorReturnType(rightValue: rightValue, newElementStack: elementStack)
    }
    
    
    // TODO: Write this out!
    private func goToParseParenthesisLeftValue() -> GeneratorReturnType {
        return goToError()
    }
    
    private func goToParseLeftValue(with function: Function) -> GeneratorReturnType {
        let (leftValue, newElementStack) = Generator().startGenerator(with: elementStack, rank: function.rank())
        elementStack = newElementStack
        
        return goToRightValue(with: ArithmeticExpression.from(function: function, leftValue: leftValue, rightValue: rightValue))
    }
    
    private func goToError() -> GeneratorReturnType {
        return GeneratorReturnType(rightValue: rightValue, newElementStack: [])
    }
}

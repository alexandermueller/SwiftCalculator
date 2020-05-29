//
//  Generator.swift
//  Calculator
//
//  Created by Alex Mueller on 2020-03-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift

typealias GeneratorReturnType = (value: ArithmeticExpression, newElementStack: [String])

class Generator {
    private var previousFunction: Function? = nil {
        didSet {
            guard let function = previousFunction else {
                return
            }
            
            rank = function.rank()
        }
    }
    private var rank: Int = .max
    private var elementStack: [String] = []
    private let bag = DisposeBag()
    
    // MARK: State Machine Functions
    
    func startGenerator(with elementStack: [String], function: Function? = nil) -> GeneratorReturnType {
        previousFunction = function
        self.elementStack = elementStack
        return goToStart()
    }
    
    private func goToStart() -> GeneratorReturnType {
        if let element = elementStack.popLast() {
            if element.isProperDouble() {
                return goToRightValue(with: .number(element.toDouble()))
            }
            
            if let button = Button.from(rawValue: element) {
                switch button {
                case .parenthesis(let parenthesis):
                    if parenthesis == .close {
                        let (rightValue, newElementStack) = goToParseParenthesisLeftValue()
                        elementStack = newElementStack
                        return goToRightValue(with: rightValue)
                    }
                case .function(let function):
                    switch function {
                    case .right(_):
                        let (leftValue, newElementStack) = Generator().startGenerator(with: elementStack, function: function)
                        elementStack = newElementStack
                        return goToRightValue(with: ArithmeticExpression.from(function: function, leftValue: leftValue))
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
        let rightValue = expression
        
        if let element = elementStack.popLast() {
            if let function = Function.from(rawValue: element) {
                switch function {
                case .left(_):
                    if rank < function.rank() {
                        elementStack += [element]
                        break
                    }
                    
                    return goToRightValue(with: ArithmeticExpression.from(function: function, leftValue: .empty, rightValue: rightValue))
                case .middle(_):
                    if let previous = previousFunction, rank < function.rank() || previous == function && previous.isGreedy() {
                        elementStack += [element]
                        break
                    }
                    
                    let (leftValue, newElementStack) = rank == function.rank() ? goToStart() : Generator().startGenerator(with: elementStack, function: function)
                    elementStack = newElementStack
                    return goToRightValue(with: ArithmeticExpression.from(function: function, leftValue: leftValue, rightValue: rightValue))
                default:
                    return goToError()
                }
            }
        }
        
        return GeneratorReturnType(value: rightValue, newElementStack: elementStack)
    }
    
    
    // TODO: Write this out!
    private func goToParseParenthesisLeftValue() -> GeneratorReturnType {
        return goToError()
    }
    
    private func goToError() -> GeneratorReturnType {
        return GeneratorReturnType(value: elementStack.count == 0 ? .empty : .error, newElementStack: [])
    }
}

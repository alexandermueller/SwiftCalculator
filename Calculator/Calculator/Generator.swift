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
        guard let element = elementStack.popLast() else {
            return goToError(with: .empty)
        }
        
        if element.isProperDouble() {
            return goToRightValue(with: .number(element.toMaxPrecisionNumber()))
        }
        
        if let button = Button.from(rawValue: element) {
            switch button {
            case .parenthesis(let parenthesis):
                if parenthesis == .close {
                    let (rightValue, newElementStack) = Generator().startGenerator(with: elementStack)
                    elementStack = newElementStack.dropLast()
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
        
        return goToError(with: .error)
    }
    
    private func goToRightValue(with expression: ArithmeticExpression) -> GeneratorReturnType {
        let rightValue = expression
        
        if let element = elementStack.popLast(), let button = Button.from(rawValue: element) {
            switch button {
            case .parenthesis(let parenthesis):
                if parenthesis == .open {
                    return GeneratorReturnType(value: rightValue, newElementStack: elementStack + [element])
                }
            case .function(let function):
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
                    return goToError(with: .error)
                }
            default:
                break
            }
        }
        
        return GeneratorReturnType(value: rightValue, newElementStack: elementStack)
    }
    
    private func goToError(with result: ArithmeticExpression) -> GeneratorReturnType {
        return GeneratorReturnType(value: result, newElementStack: [])
    }
}

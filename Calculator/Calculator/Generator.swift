//
//  Generator.swift
//  Calculator
//
//  Created by Alex Mueller on 2020-03-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift

// TODO: This CANNOT be global, should be on an object level,
// that way, when the next levels see a lower rank, it won't return once, but all the way down to the bottom.
//fileprivate var globalRank: Int = .max

struct GeneratorReturnType {
    let rightValue: ArithmeticExpression
    let missedFunction: Function?
}

class Generator {
    private var rightValue: ArithmeticExpression = .empty
    private var function: Function? = nil
    private var leftValue: ArithmeticExpression = .empty
    private var parenthesisCount: Int
    
    private let elementSubject: PublishSubject<String>
    private var transferFunction = SerialDisposable()
    private let returnSubject = PublishSubject<GeneratorReturnType>()
    private let bag = DisposeBag()
    
    private var nextLevel: Generator? = nil
    
    init(elementSubject: PublishSubject<String> = PublishSubject<String>(), parenthesisCount: Int = -1) {
        self.parenthesisCount = parenthesisCount
        self.elementSubject = elementSubject
    }
    
    // MARK: State Machine Functions
    
    func startGenerator() -> PublishSubject<GeneratorReturnType> {
        goToStart()
        return returnSubject
    }
    
    private func goToStart() {
        leftValue = .empty
        rightValue = .empty
        
        transferFunction.disposable = elementSubject.subscribe(onNext: { [unowned self] element in
            if element.isProperDouble() {
                self.goToRightValue(with: .number(element.toDouble()))
                return
            }
            
            if let button = Button.from(rawValue: element) {
                switch button {
                case .parenthesis(let parenthesis):
                    if parenthesis == .close {
                        self.goToParseLeftValue(with: self.parenthesisCount)
                        return
                    }
                case .function(let function):
                    switch function {
                    case .right(_):
                        self.goToParseLeftValue(with: function)
                        return
                    default:
                        break
                    }
                default:
                    break
                }
            }
            
            self.goToError()
        })
    }
    
    private func transferFromRightValue(input function: Function) {
        switch function {
        case .left(_):
            goToRightValue(with: ArithmeticExpression.from(function: function, leftValue: .empty, rightValue: rightValue))
            return
        case .middle(_):
            if function.rank() > globalRank { // > needs to be this way so that anything on the same level or higher will take priority
                globalRank = .max
                returnSubject.onNext(GeneratorReturnType(rightValue: rightValue, missedFunction: function))
                return
            }
            
            goToParseLeftValue(with: function)
            return
        default:
            goToError()
        }
    }
    
    private func goToRightValue(with expression: ArithmeticExpression, missedFunction: Function? = nil) {
        leftValue = .empty
        function = nil
        rightValue = expression
        nextLevel = nil
        
        // If the next level returned after seeing a function whose rank was less significant, short circuit the
        // state transfer function so that it doesn't consume the next element yet, but still processes the missed
        // function and transfers to the next appropriate state.
        if let function = missedFunction {
            globalRank = function.rank()
            transferFromRightValue(input: function)
            return
        }
        
        transferFunction.disposable = elementSubject.subscribe(onNext: { [unowned self] element in
            if let function = Function.from(rawValue: element) {
                self.transferFromRightValue(input: function)
                return
            }
            
            self.goToError()
        })
    }
    
    // TODO: Finish Parenthesis Parsing
    
    private func goToParseLeftValue(with parenthesisCount: Int) {
    }
    
    private func goToParseLeftValue(with function: Function) {
        self.function = function
        globalRank = function.rank()
        transferFunction = SerialDisposable() // Need to decouple the elementSubject and pass it to the next level (otherwise this level will interfere)
        
        nextLevel = Generator(elementSubject: elementSubject)
        nextLevel?.startGenerator().subscribe(onNext: { [unowned self] output in
            self.goToRightValue(with: output.rightValue, missedFunction: output.missedFunction)
        }).disposed(by: bag)
    }
    
    private func goToError() {
        rightValue = .error
        transferFunction = SerialDisposable()
    }
}

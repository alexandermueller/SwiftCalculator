//
//  ViewModel.swift
//  Calculator
//
//  Created by Alex Mueller on 2019-10-03.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

enum ExpressionState: Equatable {
    case zero
    case properNumber
    case modifiedNumber
    case variable
    case openParenthesis
    case closeParenthesis
    case leftFunction
    case middleFunction
    case rightFunction
}

class ViewModel {
    private var lastExpressionState: ExpressionState = .zero
    private var currentExpressionState: ExpressionState = .zero {
        didSet {
            lastExpressionState = oldValue
        }
    }
    private var parenBalance = 0 {
        didSet {
            assert(parenBalance >= 0, "There is a bug in the parenthesis matching code!")
        }
    }
    
    private let generator: Generator
    private let buttonViewModeSubject: BehaviorSubject<ButtonViewMode>
    private let memorySubject: BehaviorSubject<MaxPrecisionNumber>
    private let answerSubject: BehaviorSubject<MaxPrecisionNumber>
    private let expressionTextSubject: BehaviorSubject<String>
    private let currentValueSubject: BehaviorSubject<MaxPrecisionNumber>
    private let buttonPressSubject: PublishSubject<Button>
    private let modifiedButtonPressSubject = PublishSubject<Button>()
    private let textDisplayColourSubject: BehaviorSubject<UIColor>
    private let bag: DisposeBag
    
    private var buttonViewMode: ButtonViewMode = .normal {
        didSet {
            buttonViewModeSubject.onNext(buttonViewMode)
        }
    }

    private var memory: MaxPrecisionNumber = 0 {
        didSet {
            memorySubject.onNext(memory)
        }
    }
    private var answer: MaxPrecisionNumber = 0 {
        didSet {
            answerSubject.onNext(answer)
        }
    }
    
    private var valueStack: Stack<MaxPrecisionNumber> = Stack(from: [0])
    private var currentValue: MaxPrecisionNumber = 0 {
        didSet {
            currentValueSubject.onNext(valueStack.peek() ?? currentValue)
        }
    }
    
    private var lastMappedElements: ExpressionList = ["0"]
    private var expressionElements: ExpressionList = ["0"] {
        didSet {
            if expressionElements.isEmpty {
                return
            }
            
            expressionTextSubject.onNext(expressionElements.toExpressionString())
            
            var mappedElements: [String] = expressionElements.map({ element in
                switch Variable(rawValue: element) {
                case .some(let variable):
                    switch variable {
                    case .answer:
                        return String(answer)
                    case .memory:
                        return String(memory)
                    }
                case .none:
                    return element
                }
            })
            
            // Soft balance the parentheses so that users can preview the current value
            mappedElements += Array(repeating: Button.parenthesis(.close).rawValue(), count: parenBalance)
            let nextValue = generator.startGenerator(with: mappedElements).value.evaluate()
            
            if mappedElements == ["0"] {
                valueStack = Stack<MaxPrecisionNumber>(from: [0])
            } else if !currentValue.isNaN && mappedElements.count < lastMappedElements.count {
                valueStack.pop()
            } else if !nextValue.isNaN && mappedElements.count >= lastMappedElements.count && mappedElements != lastMappedElements {
                valueStack.push(nextValue)
            }
                           
            currentValue = nextValue
            lastMappedElements = mappedElements
        }
    }
    
    private var transferFunction = SerialDisposable()
    
    init(expressionTextSubject: BehaviorSubject<String>,
         currentValueSubject: BehaviorSubject<MaxPrecisionNumber>,
         memorySubject: BehaviorSubject<MaxPrecisionNumber>,
         answerSubject: BehaviorSubject<MaxPrecisionNumber>,
         buttonViewModeSubject: BehaviorSubject<ButtonViewMode>,
         buttonPressSubject: PublishSubject<Button>,
         textDisplayColourSubject: BehaviorSubject<UIColor>,
         bag: DisposeBag) {
        generator = Generator()
        self.buttonViewModeSubject = buttonViewModeSubject
        self.memorySubject = memorySubject
        self.answerSubject = answerSubject
        self.currentValueSubject = currentValueSubject
        self.expressionTextSubject = expressionTextSubject
        self.buttonPressSubject = buttonPressSubject
        self.textDisplayColourSubject = textDisplayColourSubject
        self.bag = bag
    }
    
    private func addExpressionElement(from button: Button) {
        guard let lastElement = expressionElements.last else {
            return
        }
        
        let lastElementIndex = expressionElements.count - 1
        
        switch (button, lastExpressionState) {
        case (.digit(_), .zero), (.parenthesis(.open), .zero), (.function(.left(_)), .zero), (.variable(_), .zero):
            expressionElements[lastElementIndex] = button.rawValue()
        case (.digit(_), .properNumber), (.digit(_), .modifiedNumber):
            expressionElements[lastElementIndex] = lastElement == "0" ? lastElement : lastElement + button.rawValue()
        case (.modifier(.decimal), .properNumber):
            expressionElements[lastElementIndex] = lastElement + button.rawValue()
        case (.modifier(.decimal), .openParenthesis), (.modifier(.decimal), .leftFunction), (.modifier(.decimal), .middleFunction):
            expressionElements += ["0" + button.rawValue()]
        default:
            expressionElements += [button.rawValue()]
        }
    }
}

// MARK: - State Machine Functions:
 
extension ViewModel {
    func startStateMachine() {
        // This persists until the application terminates. Catches input and
        // converts it depending on the current state, performs a UI level
        // modifying function, or lets the button press through.
        buttonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .function(.middle(.subtract)):
                switch self.currentExpressionState {
                case .zero, .openParenthesis, .leftFunction, .middleFunction:
                    self.modifiedButtonPressSubject.onNext(.function(.left(.negate)))
                default:
                    self.modifiedButtonPressSubject.onNext(pressedButton)
                }
            case .function(.left(.sqrt)):
                switch self.currentExpressionState {
                case .properNumber, .variable, .closeParenthesis, .rightFunction:
                    self.modifiedButtonPressSubject.onNext(.function(.middle(.root)))
                default:
                    self.modifiedButtonPressSubject.onNext(pressedButton)
                }
            case .other(let other):
                switch other {
                case .alternate:
                    self.buttonViewMode = self.buttonViewMode == .alternate ? .normal : .alternate
                case .clear:
                    self.goToZero()
                case .delete:
                    self.goToDelete()
                case .equal:
                    self.answer = self.valueStack.peek() ?? currentValue
                    self.expressionElements = self.expressionElements + []
                case .set:
                    self.memory = self.valueStack.peek() ?? currentValue
                    self.expressionElements = self.expressionElements + []
                }
            default:
                self.modifiedButtonPressSubject.onNext(pressedButton)
            }
        }).disposed(by: bag)
        
        goToZero()
    }
    
    func goToZero() {
        currentExpressionState = .zero
        
        parenBalance = 0
        expressionElements = ["0"]
        textDisplayColourSubject.onNext(.gray)
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .digit(_):
                self.goToProperNumber(with: pressedButton)
            case .modifier(_):
                self.goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: pressedButton)
            case .function(.left(_)):
                self.goToLeftFunction(with: pressedButton)
            case .function(.middle(_)):
                self.goToMiddleFunction(with: pressedButton)
            case .function(.right(_)):
                self.goToRightFunction(with: pressedButton)
            case .variable(_):
                self.goToVariable(with: pressedButton)
            default:
                return
            }
            
            self.textDisplayColourSubject.onNext(.black)
        })
    }
    
    func goToProperNumber(with buttonElement: Button? = nil) {
        currentExpressionState = .properNumber
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .digit(_):
                self.goToProperNumber(with: pressedButton)
            case .modifier(_):
                if let lastElement = self.expressionElements.last, lastElement.isInteger() {
                    self.goToModifiedNumber(with: pressedButton)
                }
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: pressedButton)
                }
            case .function(.middle(_)):
                self.goToMiddleFunction(with: pressedButton)
            case .function(.right(_)):
                self.goToRightFunction(with: pressedButton)
            default:
                return
            }
        })
    }
    
    func goToModifiedNumber(with buttonElement: Button? = nil) {
        currentExpressionState = .modifiedNumber
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .digit(_):
                self.goToProperNumber(with: pressedButton)
            default:
                return
            }
        })
    }
    
    func goToVariable(with buttonElement: Button? = nil) {
        currentExpressionState = .variable
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .function(.middle(_)):
                self.goToMiddleFunction(with: pressedButton)
            case .function(.right(_)):
                self.goToRightFunction(with: pressedButton)
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: pressedButton)
                }
            default:
                return
            }
        })
    }
    
    func goToOpenParenthesis(with buttonElement: Button? = nil) {
        currentExpressionState = .openParenthesis
        
        if let button = buttonElement {
            parenBalance += 1
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .digit(_):
                self.goToProperNumber(with: pressedButton)
            case .modifier(.decimal):
                self.goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: pressedButton)
            case .function(.left(_)):
                self.goToLeftFunction(with: pressedButton)
            case .variable(_):
                self.goToVariable(with: pressedButton)
            default:
                return
            }
        })
    }
    
    func goToCloseParenthesis(with buttonElement: Button? = nil) {
        currentExpressionState = .closeParenthesis
        
        if let button = buttonElement {
            parenBalance -= 1
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: pressedButton)
                }
            case .function(.middle(_)):
                self.goToMiddleFunction(with: pressedButton)
            case .function(.right(_)):
                self.goToRightFunction(with: pressedButton)
            default:
                return
            }
        })
    }
    
    func goToLeftFunction(with buttonElement: Button? = nil) {
        currentExpressionState = .leftFunction
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .digit(_):
                self.goToProperNumber(with: pressedButton)
            case .modifier(.decimal):
                self.goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: pressedButton)
            case .function(.left(.negate)):
                guard let lastElement = self.expressionElements.last,
                    let button = Button.from(rawValue: lastElement), button != pressedButton else {
                        return
                }
            
                self.goToLeftFunction(with: pressedButton)
            case .function(.left(_)):
                self.goToLeftFunction(with: pressedButton)
            case .variable(_):
                self.goToVariable(with: pressedButton)
            default:
                return
            }
        })
    }
    
    func goToMiddleFunction(with buttonElement: Button? = nil) {
        currentExpressionState = .middleFunction
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .digit(_):
                self.goToProperNumber(with: pressedButton)
            case .modifier(.decimal):
                self.goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: pressedButton)
            case .function(.left(_)):
                self.goToLeftFunction(with: pressedButton)
            case .variable(_):
                self.goToVariable(with: pressedButton)
            default:
                return
            }
        })
    }
    
    func goToRightFunction(with buttonElement: Button? = nil) {
        currentExpressionState = .rightFunction
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] pressedButton in
            switch pressedButton {
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: pressedButton)
                }
            case .function(.middle(_)):
                self.goToMiddleFunction(with: pressedButton)
            case .function(.right(_)):
                self.goToRightFunction(with: pressedButton)
            default:
                return
            }
        })
    }
    
    func goToDelete() {
        if let lastElement = expressionElements.last, lastElement.isOpenParen() || lastElement.isCloseParen() {
            parenBalance += lastElement.isCloseParen() ? 1 : -1
        }

        if var lastElement = expressionElements.last, lastElement.isNumber() && lastElement.count > 1 {
            lastElement.removeLast(1)
            
            if let lastCharacter = lastElement.last {
                expressionElements[expressionElements.count - 1] = lastElement
                
                switch String(lastCharacter) {
                case Button.modifier(.decimal).rawValue():
                    goToModifiedNumber()
                default:
                    goToProperNumber()
                }
                
                return
            }
        }
        
        expressionElements.removeLast(1)
        
        guard let currentExpression = expressionElements.last, expressionElements != ["0"] else {
            goToZero()
            return
        }
        
        guard let button = Button.from(rawValue: currentExpression) else {
            goToProperNumber()
            return
        }
        
        switch button {
        case .digit(_):
            goToProperNumber()
        case .parenthesis(let parenthesis):
            switch parenthesis {
            case .open:
                goToOpenParenthesis()
            case .close:
                goToCloseParenthesis()
            }
        case .function(let function):
            switch function {
            case .left(_):
                goToLeftFunction()
            case .middle(_):
                goToMiddleFunction()
            case .right(_):
                goToRightFunction()
            }
        case .variable(_):
            goToVariable()
        default:
            return
        }
    }
}

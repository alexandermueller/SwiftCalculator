//
//  ViewModel.swift
//  Calculator
//
//  Created by Alex Mueller on 2019-10-03.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation
import RxSwift

enum ExpressionState: Equatable {
    case zero
    case properDouble
    case modifiedDouble
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
    private let memorySubject: BehaviorSubject<Double>
    private let answerSubject: BehaviorSubject<Double>
    private let expressionTextSubject: BehaviorSubject<String>
    private let currentValueSubject: BehaviorSubject<Double>
    private let buttonPressSubject: PublishSubject<Button>
    private let modifiedButtonPressSubject = PublishSubject<Button>()
    private let textDisplayColourSubject: BehaviorSubject<UIColor>
    private let bag: DisposeBag
    
    private var buttonViewMode: ButtonViewMode = .normal {
        didSet {
            buttonViewModeSubject.onNext(buttonViewMode)
        }
    }

    private var memory: Double = 0 {
        didSet {
            memorySubject.onNext(memory)
        }
    }
    private var answer: Double = 0 {
        didSet {
            answerSubject.onNext(answer)
        }
    }
    
    private var expressionElements: [String] = ["0"] {
        didSet {
            if expressionElements.isEmpty {
                self.goToZero()
                return
            }
            
            expressionTextSubject.onNext(expressionElements.toExpressionString())
            
            if parenBalance == 0 {
                let elements: [String] = expressionElements.map({ element in
                    switch element {
                    case Variable.memory.rawValue:
                        return String(memory)
                    case Variable.answer.rawValue:
                        return String(answer)
                    default:
                        return element
                    }
                })

                currentValue = generator.startGenerator(with: elements).rightValue.evaluate()
                return
            }
            
            currentValue = .nan
        }
    }
    
    private var currentValue: Double = 0 {
        didSet {
            currentValueSubject.onNext(currentValue)
        }
    }
    
    private var transferFunction = SerialDisposable()
    
    init(expressionTextSubject: BehaviorSubject<String>,
         currentValueSubject: BehaviorSubject<Double>,
         memorySubject: BehaviorSubject<Double>,
         answerSubject: BehaviorSubject<Double>,
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
    
    func addExpressionElement(from button: Button) {
        guard let lastElement = expressionElements.last else {
            return
        }
        
        let lastElementIndex = expressionElements.count - 1
        
        switch button {
        case .digit(_):
            switch lastExpressionState {
            case .zero:
                expressionElements[lastElementIndex] = button.rawValue()
            case .properDouble, .modifiedDouble:
                expressionElements[lastElementIndex] = lastElement == "0" ? lastElement : lastElement + button.rawValue()
            default:
                expressionElements += [button.rawValue()]
            }
        case .modifier(.decimal):
            expressionElements[lastElementIndex] = lastElement + button.rawValue()
        case .parenthesis(.open):
            switch lastExpressionState {
            case .zero:
                expressionElements[lastElementIndex] = button.rawValue()
            default:
                expressionElements += [button.rawValue()]
            }
        case .function(.left(_)):
            switch lastExpressionState {
            case .zero:
                expressionElements[lastElementIndex] = button.rawValue()
            default:
                expressionElements += [button.rawValue()]
            }
        case .variable(_):
            switch lastExpressionState {
            case .zero:
                expressionElements[lastElementIndex] = button.rawValue()
            default:
                expressionElements += [button.rawValue()]
            }
        default:
            expressionElements += [button.rawValue()]
        }
    }
    
    // MARK: State Machine Functions
    
    func startStateMachine() {
        // This persists until the application terminates. Catches input and
        // converts it depending on the current state, performs a UI level
        // modifying function, or lets the button press through.
        buttonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .function(.middle(.subtract)):
                switch self.currentExpressionState {
                case .zero, .openParenthesis, .leftFunction, .middleFunction:
                    self.modifiedButtonPressSubject.onNext(.function(.left(.negate)))
                default:
                    self.modifiedButtonPressSubject.onNext(buttonPressed)
                }
            case .function(.left(.sqrt)):
                switch self.currentExpressionState {
                case .properDouble, .variable, .closeParenthesis, .rightFunction:
                    self.modifiedButtonPressSubject.onNext(.function(.middle(.root)))
                default:
                    self.modifiedButtonPressSubject.onNext(buttonPressed)
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
                    self.expressionElements = self.expressionElements + []
                    self.answer = self.currentValue
                case .set:
                    self.expressionElements = self.expressionElements + []
                    self.memory = self.currentValue
                }
            default:
                self.modifiedButtonPressSubject.onNext(buttonPressed)
            }
        }).disposed(by: bag)
        
        goToZero()
    }
    
    func goToZero() {
        currentExpressionState = .zero
        
        parenBalance = 0
        expressionElements = ["0"]
        textDisplayColourSubject.onNext(.gray)
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .digit(_):
                self.goToProperDouble(with: buttonPressed)
            case .modifier(_):
                self.goToModifiedDouble(with: buttonPressed)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: buttonPressed)
            case .function(.left(_)):
                self.goToLeftFunction(with: buttonPressed)
            case .function(.middle(_)):
                self.goToMiddleFunction(with: buttonPressed)
            case .function(.right(_)):
                self.goToRightFunction(with: buttonPressed)
            case .variable(_):
                self.goToVariable(with: buttonPressed)
            default:
                return
            }
            
            self.textDisplayColourSubject.onNext(.black)
        })
    }
    
    func goToProperDouble(with buttonElement: Button? = nil) {
        currentExpressionState = .properDouble
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .digit(_):
                self.goToProperDouble(with: buttonPressed)
            case .modifier(_):
                if let lastElement = self.expressionElements.last, lastElement.isInt() {
                    self.goToModifiedDouble(with: buttonPressed)
                }
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: buttonPressed)
                }
            case .function(.middle(_)):
                self.goToMiddleFunction(with: buttonPressed)
            case .function(.right(_)):
                self.goToRightFunction(with: buttonPressed)
            default:
                return
            }
        })
    }
    
    func goToModifiedDouble(with buttonElement: Button? = nil) {
        currentExpressionState = .modifiedDouble
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .digit(_):
                self.goToProperDouble(with: buttonPressed)
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
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .function(.middle(_)):
                self.goToMiddleFunction(with: buttonPressed)
            case .function(.right(_)):
                self.goToRightFunction(with: buttonPressed)
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: buttonPressed)
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
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .digit(_):
                self.goToProperDouble(with: buttonPressed)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: buttonPressed)
            case .function(.left(_)):
                self.goToLeftFunction(with: buttonPressed)
            case .variable(_):
                self.goToVariable(with: buttonPressed)
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
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: buttonPressed)
                }
            case .function(.middle(_)):
                self.goToMiddleFunction(with: buttonPressed)
            case .function(.right(_)):
                self.goToRightFunction(with: buttonPressed)
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
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .digit(_):
                self.goToProperDouble(with: buttonPressed)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: buttonPressed)
            case .function(.left(.sqrt)):
                self.goToLeftFunction(with: buttonPressed)
            case .function(.left(.negate)):
                guard let lastElement = self.expressionElements.last,
                      let button = Button.from(rawValue: lastElement), button != buttonPressed else {
                    return
                }
                
                self.goToLeftFunction(with: buttonPressed)
            case .variable(_):
                self.goToVariable(with: buttonPressed)
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
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .digit(_):
                self.goToProperDouble(with: buttonPressed)
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: buttonPressed)
            case .function(.left(_)):
                self.goToLeftFunction(with: buttonPressed)
            case .variable(_):
                self.goToVariable(with: buttonPressed)
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
        
        transferFunction.disposable = modifiedButtonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: buttonPressed)
                }
            case .function(.middle(_)):
                self.goToMiddleFunction(with: buttonPressed)
            case .function(.right(_)):
                self.goToRightFunction(with: buttonPressed)
            default:
                return
            }
        })
    }
    
    func goToDelete() {
        if let lastElement = expressionElements.popLast() {
            parenBalance += lastElement.isCloseParen() ? 1 : lastElement.isOpenParen() ? -1 : 0
        }
        
        guard let currentExpression = expressionElements.last, expressionElements != ["0"] else {
            goToZero()
            return
        }
        
        guard let button = Button.from(rawValue: currentExpression) else {
            // The value that falls through can only be a double that doesn't
            // map to a digit, if it does it will be caught below in the switch.
            goToProperDouble()
            return
        }
        
        switch button {
        case .digit(_):
            self.goToProperDouble()
        case .parenthesis(let parenthesis):
            switch parenthesis {
            case .open:
                self.goToOpenParenthesis()
            case .close:
                self.goToCloseParenthesis()
            }
        case .function(let function):
            switch function {
            case .left(let left):
                switch left {
                case .negate:
                    goToDelete()
                    return
                default:
                    goToLeftFunction()
                }
            case .middle(_):
                self.goToMiddleFunction()
            case .right(_):
                self.goToRightFunction()
            }
        case .variable(_):
            self.goToVariable()
        default:
            return
        }
    }
}

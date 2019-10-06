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
    private var currentExpressionState: ExpressionState = .zero
    private var parenBalance = 0 {
        didSet {
            assert(parenBalance >= 0, "There is a bug in the parenthesis matching code!")
        }
    }
    
    private let buttonViewModeSubject: BehaviorSubject<ButtonViewMode>
    private let memorySubject: BehaviorSubject<Double>
    private let answerSubject: BehaviorSubject<Double>
    private let expressionTextSubject: BehaviorSubject<String>
    private let currentValueSubject: BehaviorSubject<Double>
    private let buttonPressSubject: PublishSubject<Button>
    private let modifiedButtonPressSubject = PublishSubject<Button>()
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
                expressionElements = ["0"]
                return
            }
            
            expressionTextSubject.onNext(expressionElements.toExpressionString())
            currentValue = parenBalance > 0 ? .nan : parseExpression(expressionElements.map({
                switch $0 {
                case Variable.memory.rawValue:
                    return String(memory)
                case Variable.answer.rawValue:
                    return String(answer)
                default:
                    return $0
                }
            })).evaluate()
        }
    }
    
    private var currentValue: Double = 0 {
        didSet {
            currentValueSubject.onNext(currentValue)
        }
    }
    
    private var transferFunction: SerialDisposable = SerialDisposable()
    
    init(expressionTextSubject: BehaviorSubject<String>,
         currentValueSubject: BehaviorSubject<Double>,
         memorySubject: BehaviorSubject<Double>,
         answerSubject: BehaviorSubject<Double>,
         buttonViewModeSubject: BehaviorSubject<ButtonViewMode>,
         buttonPressSubject: PublishSubject<Button>,
         bag: DisposeBag) {
        self.buttonViewModeSubject = buttonViewModeSubject
        self.memorySubject = memorySubject
        self.answerSubject = answerSubject
        self.currentValueSubject = currentValueSubject
        self.expressionTextSubject = expressionTextSubject
        self.buttonPressSubject = buttonPressSubject
        self.bag = bag
    }
    
    func addExpressionElement(from button: Button) {
        switch button {
        case .modifier(let modifier):
            switch modifier {
            case .decimal:
                let count = expressionElements.count
                expressionElements[count - 1] = expressionElements[count - 1] + button.rawValue()
            }
        default:
            expressionElements += [button.rawValue()]
        }
    }
    
    // MARK: State Machine Functions
    
    func startStateMachine() {
        // This persists until the application terminates
        buttonPressSubject.subscribe(onNext: { [unowned self] buttonPressed in
            switch buttonPressed {
            case .function(.middle(.subtract)):
                switch self.currentExpressionState {
                case .zero, .openParenthesis, .leftFunction, .middleFunction:
                    self.modifiedButtonPressSubject.onNext(.function(.left(.negate)))
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
                    self.answer = self.currentValue
                case .set:
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
        
        expressionElements = ["0"]
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
            addExpressionElement(from: button)
        }
        
        parenBalance += 1
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
            addExpressionElement(from: button)
        }
        
        parenBalance -= 1
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
            case .modifier(_):
                self.goToModifiedDouble(with: buttonPressed)
            case .parenthesis(.close):
                if self.parenBalance > 0 {
                    self.goToCloseParenthesis(with: buttonPressed)
                }
            case .parenthesis(.open):
                self.goToOpenParenthesis(with: buttonPressed)
            case .function(.left(.sqrt)):
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
        expressionElements.removeLast(1)
        
        guard let currentExpression = expressionElements.last else {
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
                case .sqrt:
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
//        let expressionCount = expressionList.count
//        let lastExpression: String = expressionList[expressionCount - 1]
//
//        let allowNegationList: [String] = (Function.allCases.map({$0.rawValue}) + [Parenthesis.open.rawValue]).filter({![Function.negate.rawValue, Function.factorial.rawValue, Parenthesis.close.rawValue].contains($0)})
//        let canNegate = allowNegationList.contains(lastExpression) || expressionList.suffix(1) = ["0"] && (expressionCount == 1 || expressionCount > 2 && expressionList[expressionCount - 2] != Function.negate.rawValue)
//        let button: Button = canNegate && buttonPressed == .function(.subtract) ? .function(.negate) : buttonPressed
//        let buttonText = button.rawValue()
//
//        switch buttonPressed {
//        case .variable(_):
//            if lastExpression.isDouble() && lastExpression != "0" {
//                return
//            }
//
//            fallthrough
//        case .digit(_):
//            if lastExpression.isCloseParen() || lastExpression.isVariable() {
//                return
//            }
//
//            if lastExpression.isDouble() {
//                expressionList[expressionCount - 1] = lastExpression == "0" ? buttonText : lastExpression + buttonText
//            } else {
//                expressionList += [buttonText]
//            }
//        case .modifier(let modifier):
//            switch modifier {
//            case .decimal:
//                if lastExpression.isInt() {
//                    expressionList[expressionCount - 1] = lastExpression + buttonText
//                }
//            }
//        case .parenthesis(let parenthesis):
//            switch parenthesis {
//            case .open:
//                if lastExpression == "0" {
//                    expressionList[expressionCount - 1] = buttonText
//                    parenBalance += 1
//                    return
//                }
//
//                if lastExpression.isCloseParen() || lastExpression.isDouble() {
//                    return
//                }
//
//                parenBalance += 1
//                expressionList += [buttonText]
//            case .close:
//                if !lastExpression.isProperDouble() && !lastExpression.isCloseParen() || parenBalance == 0 {
//                    return
//                }
//
//                expressionList += [buttonText]
//                parenBalance -= 1
//            }
//        case .function(let functionType):
//            switch functionType {
//            case .left(let leftFunction):
//                switch leftFunction {
//                case .negate:
//                    guard canNegate else {
//                        return
//                    }
//                case .sqrt:
//                }
//            case .middle(let function):
//
//            case .right(let function):
//
////            case .negate:
////                guard canNegate else {
////                    return
////                }
////            case .sqrt:
////                let allowSqrtList = allowNegationList + [Function.negate.rawValue]
////                let canSqrt = allowSqrtList.contains(lastExpression) || lastExpression == "0"
////                guard button == .function(.sqrt) && canSqrt else {
////                    return
////                }
////
////                if lastExpression == "0" {
////                    expressionList[expressionCount - 1] = buttonText
////                    expressionList += ["0"]
////                } else if allowNegationList.contains(lastExpression) && button == .function(.negate) ||
////                          allowSqrtList.contains(lastExpression) && button == .function(.sqrt){
////                    expressionList += [buttonText, "0"]
////                }
////            case .add, .subtract, .multiply, .divide, .exponent, .root, .factorial: // These come after the expression
////                guard lastExpression.isCloseParen() || lastExpression.isProperDouble() || lastExpression.isFactorial() else {
////                    return
////                }
////
////                expressionList += [buttonText]
//            }
//        case .setter(let setter):
//            switch setter {
//            case .equal:
//                expressionList = Array(expressionList) // Allows for value stepping!
//                answer = currentValue
//            case .set:
//                memory = currentValue
//            }
//        case .other(let other):
//            switch other {
//            case .alternate:
//                buttonViewMode = buttonViewMode == .normal ? .alternate : .normal
//            case .delete:
//                parenBalance += lastExpression.isCloseParen() ? 1 : lastExpression.isOpenParen() ? -1 : 0
//
//                // Maybe someday we'll get digit deletion working...
//                expressionList = expressionList.dropLast()
//                let lastExpression = expressionList[expressionList.count - 1]
//
//                if lastExpression == Function.negate.rawValue {
//                    expressionList = expressionList.dropLast()
//                } else if lastExpression == Function.sqrt.rawValue {
//                    expressionList += ["0"]
//                }
//            case .clear:
//                expressionList = []
//                parenBalance = 0
//            }
//        }
//    }
}

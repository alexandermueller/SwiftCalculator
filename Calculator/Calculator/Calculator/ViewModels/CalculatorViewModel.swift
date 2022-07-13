//
//  CalculatorViewModel.swift
//  Swift Calculator
//
//  Created by Alex Müller on 16.05.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

typealias ButtonMappings = [Button : Button]
typealias VariableValueDict = [Variable : MaxPrecisionNumber]

final class CalculatorViewModel: ObservableObject {
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

    @Published var expressionText: String = "0"
    @Published var displayedValue: MaxPrecisionNumber = 0
    @Published var variableValueDict: VariableValueDict = Variable.defaultVariableValueDict
    @Published var textDisplayColour: Color = .gray
    @Published var buttonDisplayViewMode: ButtonDisplayView.Mode = .normal
    @Published var buttonLongPressed: Button? {
        didSet {
            guard let button = buttonLongPressed, let mapping = button.longPressMapping else { return }
            buttonPressed = mapping
        }
    }
    @Published var buttonPressed: Button? {
        didSet {
            switch buttonPressed {
            case .function(.middle(.subtract)):
                switch currentExpressionState {
                case .zero, .openParenthesis, .leftFunction, .middleFunction:
                    modifiedButtonPressed = .function(.left(.negate))
                default:
                    modifiedButtonPressed = buttonPressed
                }
            case .function(.left(.sqrt)):
                switch self.currentExpressionState {
                case .properNumber, .variable, .closeParenthesis, .rightFunction:
                    modifiedButtonPressed = .function(.middle(.root))
                default:
                    modifiedButtonPressed = buttonPressed
                }
            case .convenience(let convenience):
                switch convenience {
                case .fraction:
                    simulate(pressedButtonCombo: [.parenthesis(.open), .digit(.one), .function(.middle(.divide))])
                case .square:
                    simulate(pressedButtonCombo: [.function(.middle(.exponent)), .digit(.two)])
                }
            case .other(let other):
                switch other {
                case .alternate:
                    buttonDisplayViewMode = buttonDisplayViewMode == .alternate ? .normal : .alternate
                case .clear:
                    goToZero()
                case .delete:
                    goToDelete()
                case .equal:
                    variableValueDict[.answer] = valueStack.peek() ?? currentValue
                    expressionElements = expressionElements + []
                case .set:
                    variableValueDict[.memory] = valueStack.peek() ?? currentValue
                    expressionElements = expressionElements + []
                }
            default:
                modifiedButtonPressed = buttonPressed
            }
        }
    }
    private var modifiedButtonPressed: Button? {
        didSet {
            guard let modifiedButtonPressed = modifiedButtonPressed else { return }
            transferFunction?(modifiedButtonPressed)
        }
    }
    
    private let generator = Generator()
    
    private var valueStack: Stack<MaxPrecisionNumber> = Stack(from: [0])
    private var currentValue: MaxPrecisionNumber = 0 {
        didSet {
            displayedValue = valueStack.peek() ?? currentValue
        }
    }
    private var lastMappedElements: ExpressionList = .defaultList
    private var expressionElements: ExpressionList = .defaultList {
        didSet {
            guard !expressionElements.isEmpty else { return }
            
            expressionText = expressionElements.toExpressionString()
            
            var mappedElements: [String] = expressionElements.map({ element in
                switch Variable(rawValue: element) {
                case .some(let variable):
                    return String(variableValueDict[variable, default: 0])
                case .none:
                    return element
                }
            })
            
            // Soft balance the parentheses so that users can preview the current value
            mappedElements += Array(repeating: Button.parenthesis(.close).rawValue, count: parenBalance)
            let nextValue = generator.startGenerator(with: mappedElements).value.evaluate()

            let mappedExpressionString = mappedElements.toExpressionString()
            let lastMappedExpressionString = lastMappedElements.toExpressionString()
            
            if mappedExpressionString == "0" {
                valueStack = Stack<MaxPrecisionNumber>(from: [0])
            } else if !currentValue.isNaN && mappedExpressionString.count < lastMappedExpressionString.count {
                valueStack.pop()
            } else if !nextValue.isNaN && mappedExpressionString.count >= lastMappedExpressionString.count && mappedExpressionString != lastMappedExpressionString {
                valueStack.push(nextValue)
            }
            
            currentValue = nextValue
            lastMappedElements = mappedElements
        }
    }
    
    private var lastExpressionState: ExpressionState = .zero
    private var currentExpressionState: ExpressionState = .zero {
        didSet {
            lastExpressionState = oldValue
        }
    }
    private var transferFunction: ((Button) -> Void)? = nil
    
    private var parenBalance = 0 {
        didSet {
            assert(parenBalance >= 0, "There is a bug in the parenthesis matching code!")
        }
    }
    
    init() {
        goToZero()
    }
    
    private func addExpressionElement(from button: Button) {
        guard let lastElement = expressionElements.last else { return }
        
        let lastElementIndex = expressionElements.count - 1
        
        switch (button, lastExpressionState) {
        case (.digit, .zero), (.parenthesis(.open), .zero), (.function(.left), .zero), (.variable, .zero):
            expressionElements[lastElementIndex] = button.rawValue
        case (.digit, .properNumber), (.digit, .modifiedNumber):
            expressionElements[lastElementIndex] = lastElement == "0" ? lastElement : lastElement + button.rawValue
        case (.modifier(.decimal), .properNumber):
            expressionElements[lastElementIndex] = lastElement + button.rawValue
        case (.modifier(.decimal), .openParenthesis), (.modifier(.decimal), .leftFunction), (.modifier(.decimal), .middleFunction):
            expressionElements += .defaultList
            expressionElements += [button.rawValue]
        default:
            expressionElements += [button.rawValue]
        }
    }
}

// MARK: - State Machine

extension CalculatorViewModel {
    func simulate(pressedButtonCombo: [Button]) {
        guard let firstButton = pressedButtonCombo.first else { return }
        
        let lastExpressionElements = expressionElements
        modifiedButtonPressed = firstButton
        
        if expressionElements != lastExpressionElements {
            for pressedButton in pressedButtonCombo.dropFirst() {
                modifiedButtonPressed = pressedButton
            }
        }
    }
    
    func goToZero() {
        currentExpressionState = .zero
        
        parenBalance = 0
        expressionElements = .defaultList
        textDisplayColour = .gray
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .digit:
                goToProperNumber(with: pressedButton)
            case .modifier:
                goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                goToOpenParenthesis(with: pressedButton)
            case .function(.left):
                goToLeftFunction(with: pressedButton)
            case .function(.middle):
                goToMiddleFunction(with: pressedButton)
            case .function(.right):
                goToRightFunction(with: pressedButton)
            case .variable:
                goToVariable(with: pressedButton)
            default:
                return
            }
            
            textDisplayColour = Color(light: .black, dark: .white)
        }
    }
    
    func goToProperNumber(with buttonElement: Button? = nil) {
        currentExpressionState = .properNumber
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .digit:
                goToProperNumber(with: pressedButton)
            case .modifier:
                if let lastElement = expressionElements.last, lastElement.isInteger() {
                    goToModifiedNumber(with: pressedButton)
                }
            case .parenthesis(.close):
                goToCloseParenthesis(with: pressedButton)
            case .function(.middle):
                goToMiddleFunction(with: pressedButton)
            case .function(.right):
                goToRightFunction(with: pressedButton)
            default:
                return
            }
        }
    }
    
    func goToModifiedNumber(with buttonElement: Button? = nil) {
        currentExpressionState = .modifiedNumber
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .digit:
                goToProperNumber(with: pressedButton)
            default:
                return
            }
        }
    }
    
    func goToVariable(with buttonElement: Button? = nil) {
        currentExpressionState = .variable
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .function(.middle):
                goToMiddleFunction(with: pressedButton)
            case .function(.right):
                goToRightFunction(with: pressedButton)
            case .parenthesis(.close):
                goToCloseParenthesis(with: pressedButton)
            default:
                return
            }
        }
    }
    
    func goToOpenParenthesis(with buttonElement: Button? = nil) {
        currentExpressionState = .openParenthesis
        
        if let button = buttonElement {
            parenBalance += 1
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .digit:
                goToProperNumber(with: pressedButton)
            case .modifier(.decimal):
                goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                goToOpenParenthesis(with: pressedButton)
            case .function(.left):
                goToLeftFunction(with: pressedButton)
            case .variable:
                goToVariable(with: pressedButton)
            default:
                return
            }
        }
    }
    
    func goToCloseParenthesis(with buttonElement: Button? = nil) {
        guard parenBalance > 0 else { return }
        
        currentExpressionState = .closeParenthesis
        
        if let button = buttonElement {
            parenBalance -= 1
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .parenthesis(.close):
                goToCloseParenthesis(with: pressedButton)
            case .function(.middle):
                goToMiddleFunction(with: pressedButton)
            case .function(.right):
                goToRightFunction(with: pressedButton)
            default:
                return
            }
        }
    }
    
    func goToLeftFunction(with buttonElement: Button? = nil) {
        currentExpressionState = .leftFunction
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .digit:
                goToProperNumber(with: pressedButton)
            case .modifier(.decimal):
                goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                goToOpenParenthesis(with: pressedButton)
            case .function(.left(.negate)):
                guard let lastElement = expressionElements.last, let button = Button.from(rawValue: lastElement), button != pressedButton else { return }
                goToLeftFunction(with: pressedButton)
            case .function(.left):
                goToLeftFunction(with: pressedButton)
            case .variable:
                goToVariable(with: pressedButton)
            default:
                return
            }
        }
    }
    
    func goToMiddleFunction(with buttonElement: Button? = nil) {
        currentExpressionState = .middleFunction
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .digit:
                goToProperNumber(with: pressedButton)
            case .modifier(.decimal):
                goToModifiedNumber(with: pressedButton)
            case .parenthesis(.open):
                goToOpenParenthesis(with: pressedButton)
            case .function(.left):
                goToLeftFunction(with: pressedButton)
            case .variable:
                goToVariable(with: pressedButton)
            default:
                return
            }
        }
    }
    
    func goToRightFunction(with buttonElement: Button? = nil) {
        currentExpressionState = .rightFunction
        
        if let button = buttonElement {
            addExpressionElement(from: button)
        }
        
        transferFunction = { [unowned self] pressedButton in
            switch pressedButton {
            case .parenthesis(.close):
                goToCloseParenthesis(with: pressedButton)
            case .function(.middle):
                goToMiddleFunction(with: pressedButton)
            case .function(.right):
                goToRightFunction(with: pressedButton)
            default:
                return
            }
        }
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
                case Button.modifier(.decimal).rawValue:
                    goToModifiedNumber()
                default:
                    goToProperNumber()
                }
                
                return
            }
        }
        
        expressionElements.removeLast(1)
        
        guard let currentExpression = expressionElements.last, expressionElements != .defaultList else {
            goToZero()
            return
        }
        
        guard let button = Button.from(rawValue: currentExpression) else {
            goToProperNumber()
            return
        }
        
        switch button {
        case .digit:
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
            case .left:
                goToLeftFunction()
            case .middle:
                goToMiddleFunction()
            case .right:
                goToRightFunction()
            }
        case .variable:
            goToVariable()
        default:
            return
        }
    }
}

// MARK: - Button Extension

extension Button {
    static var longPressMappings: ButtonMappings {
        [.other(.delete) : .other(.clear), .other(.equal) : .other(.set)]
    }
    
    var hasLongPressMapping: Bool {
        longPressMapping != nil
    }
    
    var longPressMapping: Button? {
        Button.longPressMappings[self]
    }
}


// MARK: - Variable Extension

extension Variable {
    static var defaultVariableValueDict: VariableValueDict {
        var variableValueDict: VariableValueDict = [:]
        
        for variable in allCases {
            variableValueDict[variable] = 0
        }
        
        return variableValueDict
    }
}

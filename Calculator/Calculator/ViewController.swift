//
//  ViewController.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-09.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import UIKit

enum Digit: String, CaseIterable {
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
}

enum Modifier: String, CaseIterable {
    case decimal = "."
}

enum Parenthesis: String, CaseIterable {
    case open = "("
    case close = ")"
}

// NOTE: This has been sorted by increasing order of precedence.
enum Function: String, CaseIterable {
    case add = "+"
    case subtract = "-"
    case multiply = "x"
    case divide = "÷"
    case exponent = "^"
    case root = "√"
}

enum Variable: String, CaseIterable {
    case answer = "ANS"
    case memory = "MEM"
}

enum Setter: String, CaseIterable {
    case equal = "="
    case set = "SET"
}

enum Other: String, CaseIterable {
    case alternate = "ALT"
    case delete = "DEL"
    case clear = "CLR"
}

enum Button: Equatable {
    case digit(Digit)
    case modifier(Modifier)
    case parenthesis(Parenthesis)
    case function(Function)
    case variable(Variable)
    case setter(Setter)
    case other(Other)
    
    
    // TDOD: This needs a unit test to ensure that all the types have been accounted for.
    static func from(rawValue: String) -> Button? {
        if let digit = Digit(rawValue: rawValue) {
            return .digit(digit)
        } else if let modifier = Modifier(rawValue: rawValue) {
            return .modifier(modifier)
        } else if let parenthesis = Parenthesis(rawValue: rawValue) {
            return .parenthesis(parenthesis)
        } else if let function = Function(rawValue: rawValue) {
            return .function(function)
        } else if let variable = Variable(rawValue: rawValue) {
            return .variable(variable)
        } else if let setter = Setter(rawValue: rawValue) {
            return .setter(setter)
        } else if let other = Other(rawValue: rawValue) {
            return .other(other)
        }
        
        return nil
    }
    
    func rawValue() -> String {
        switch self {
        case .digit(let button):
            return button.rawValue
        case .modifier(let button):
            return button.rawValue
        case .parenthesis(let button):
            return button.rawValue
        case .function(let button):
            return button.rawValue
        case .variable(let button):
            return button.rawValue
        case .setter(let button):
            return button.rawValue
        case .other(let button):
            return button.rawValue
        }
    }
}

let kInactiveButtonColor: UIColor = .brown
let kActiveButtonColor: UIColor = .orange
let kViewMargin: CGFloat = 2
let kLabelFontToHeightRatio: CGFloat = 0.33

class ViewController: UIViewController {
    let backgroundView = UIView()
    let textDisplayLabel = UILabel()
    let valueDisplayLabel = UILabel()
    let variableView = UIView()
    let buttonView = UIView()
    let normalButtonView = UIView()
    let alternateButtonView = UIView()
    
    var variableSubviews: [String : UILabel] = [:]
    
    var currentState: UIControl.State = .normal
    var expressionList: [String] = ["0"] {
        didSet {
            if expressionList.isEmpty {
                expressionList = ["0"]
            }
            
            textDisplayLabel.text = expressionList.joined(separator: " ") + " ="
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
    var currentValue: Double = 0 {
        didSet {
            valueDisplayLabel.text = currentValue.toSimpleNumericString()
        }
    }
    var parenBalance: Int = 0
    var memory: Double = 0 {
        didSet {
            guard let memoryValueDisplayLabel = variableSubviews[Variable.memory.rawValue] else {
                return
            }

            memoryValueDisplayLabel.text = "= " + memory.toSimpleNumericString(true) + " "
        }
    }
    var answer: Double = 0 {
        didSet {
            guard let answerValueDisplayLabel = variableSubviews[Variable.answer.rawValue] else {
                return
            }
            
            answerValueDisplayLabel.text = "= " + answer.toSimpleNumericString(true) + " "
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        backgroundView.frame = view.frame
        backgroundView.backgroundColor = .black
        
        buttonView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        buttonView.isOpaque = false
        
        let normalButtonLayout: [[Button]] = [[       .digit(.zero),  .modifier(.decimal),    .setter(.equal),      .function(.add) ],
                                              [        .digit(.one),         .digit(.two),     .digit(.three), .function(.subtract) ],
                                              [       .digit(.four),        .digit(.five),       .digit(.six), .function(.multiply) ],
                                              [      .digit(.seven),       .digit(.eight),      .digit(.nine),   .function(.divide) ],
                                              [ .parenthesis(.open), .parenthesis(.close), .variable(.answer), .function(.exponent) ],
                                              [  .other(.alternate),       .other(.clear),    .other(.delete),     .function(.root) ]]
        
        let alternateButtonLayout: [[Button]] = [[       .digit(.zero),  .modifier(.decimal),      .setter(.set),      .function(.add) ],
                                                 [        .digit(.one),         .digit(.two),     .digit(.three), .function(.subtract) ],
                                                 [       .digit(.four),        .digit(.five),       .digit(.six), .function(.multiply) ],
                                                 [      .digit(.seven),       .digit(.eight),      .digit(.nine),   .function(.divide) ],
                                                 [ .parenthesis(.open), .parenthesis(.close), .variable(.memory), .function(.exponent) ],
                                                 [  .other(.alternate),       .other(.clear),    .other(.delete),     .function(.root) ]]
        
        assert(normalButtonLayout.count == alternateButtonLayout.count && normalButtonLayout[0].count == alternateButtonLayout[0].count)
        
        let buttonW = buttonView.frame.width / CGFloat(normalButtonLayout[0].count)
        let buttonH = buttonView.frame.height / CGFloat(normalButtonLayout.count)
        var buttonPointSize: CGFloat = 0
        
        for (layout, buttonSubview, isVisible) in [(normalButtonLayout, normalButtonView, true), (alternateButtonLayout, alternateButtonView, false)] {
            buttonSubview.frame = CGRect(x: 0, y: 0, width: buttonView.frame.width, height: buttonView.frame.height)
            buttonSubview.isOpaque = false
            buttonSubview.isHidden = !isVisible
            
            for (rowIndex, row) in layout.enumerated() {
                let buttonY = buttonView.frame.height - CGFloat(rowIndex + 1) * buttonH
                
                for (columnIndex, buttonType) in row.enumerated() {
                    let buttonX = CGFloat(columnIndex % 4) * buttonW
                    
                    let button = UIButton()
                    button.frame = CGRect(x: buttonX, y: buttonY, width: buttonW, height: buttonH)
                    button.setTitle(buttonType.rawValue(), for: .normal)
                    button.backgroundColor = kInactiveButtonColor
                    button.setTitleColor(layout == alternateButtonLayout && buttonType == .other(.alternate) ? kActiveButtonColor : .white, for: .normal)
                    button.addTarget(self, action: #selector(buttonTouchDown), for: UIControl.Event.touchDown)
                    button.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControl.Event.touchUpInside)
                    button.addTarget(self, action: #selector(buttonTouchUpOutside), for: UIControl.Event.touchUpOutside)
                    
                    buttonSubview.addSubview(button)
                    
                    if let label = button.titleLabel, buttonPointSize == 0 {
                        buttonPointSize = label.font.pointSize
                    }
                }
            }
            
            buttonView.addSubview(buttonSubview)
        }
        
        let textDisplayLabelY: CGFloat = 35
        let textDisplayLabelH: CGFloat = 99
        
        textDisplayLabel.frame = CGRect(x: 0, y: textDisplayLabelY, width: view.frame.width, height: textDisplayLabelH)
        textDisplayLabel.backgroundColor = .white
        textDisplayLabel.textColor = .black
        textDisplayLabel.textAlignment = .right
        textDisplayLabel.adjustsFontSizeToFitWidth = true
        textDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: textDisplayLabelH * kLabelFontToHeightRatio)
        
        let variableViewH = buttonH
        let valueDisplayLabelY = textDisplayLabelY + textDisplayLabelH + kViewMargin
        let valueDisplayLabelH = view.frame.height * 0.5 - valueDisplayLabelY - variableViewH - kViewMargin
        
        valueDisplayLabel.frame = CGRect(x: 0, y: valueDisplayLabelY, width: view.frame.width, height: valueDisplayLabelH)
        valueDisplayLabel.backgroundColor = .white
        valueDisplayLabel.textColor = .brown
        valueDisplayLabel.textAlignment = .right
        valueDisplayLabel.adjustsFontSizeToFitWidth = true
        valueDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: valueDisplayLabelH * kLabelFontToHeightRatio)
        
        buttonView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        buttonView.isOpaque = false
        
        expressionList = ["0"]
        
        let variableCount: CGFloat = CGFloat(Variable.allCases.count)
        let variableViewY = valueDisplayLabelY + valueDisplayLabelH + kViewMargin
        let variableViewW = view.frame.width
        
        let variableSubviewW: CGFloat = variableViewW / variableCount
        
        variableView.frame = CGRect(x: 0, y: variableViewY, width: variableViewW, height: variableViewH)
        variableView.isOpaque = true
        variableView.backgroundColor = kInactiveButtonColor
        
        for (index, variable) in Variable.allCases.enumerated() {
            let variableSubviewX: CGFloat = CGFloat(index) * variableViewW / variableCount

            let variableSubview = UIView()
            variableSubview.frame = CGRect(x: variableSubviewX, y: 0, width: variableSubviewW, height: variableViewH)
            variableSubview.isOpaque = false
            
            let variableTitleLabel = UILabel()
            variableTitleLabel.frame = CGRect(x: 0, y: 0, width: buttonW, height: buttonH)
            variableTitleLabel.backgroundColor = kInactiveButtonColor
            variableTitleLabel.textColor = kActiveButtonColor
            variableTitleLabel.textAlignment = .center
            variableTitleLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: buttonPointSize)
            variableTitleLabel.text = variable.rawValue
            
            let variableValueDisplayLabel = UILabel()
            variableValueDisplayLabel.frame = CGRect(x: buttonW + 1, y: 0, width: variableSubviewW - buttonW, height: buttonH)
            variableValueDisplayLabel.backgroundColor = kInactiveButtonColor
            variableValueDisplayLabel.textColor = kActiveButtonColor
            variableValueDisplayLabel.textAlignment = .center
            variableValueDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: buttonPointSize)
            
            variableSubviews[variable.rawValue] = variableValueDisplayLabel
            
            variableSubview.addSubview(variableTitleLabel)
            variableSubview.addSubview(variableValueDisplayLabel)
            variableView.addSubview(variableSubview)
        }
        
        memory = 0
        answer = 0
        
        view.addSubview(backgroundView)
        view.addSubview(textDisplayLabel)
        view.addSubview(valueDisplayLabel)
        view.addSubview(variableView)
        view.addSubview(buttonView)
    }
    
    @objc func buttonTouchDown(sender: UIButton!) {
        sender.backgroundColor = kActiveButtonColor
    }
    
    @objc func buttonTouchUpInside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
        
        guard let buttonText: String = sender.title(for: currentState),
              let button: Button = Button.from(rawValue: buttonText) else {
            return
        }
        
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
                answer = currentValue
            case .set:
                memory = currentValue
            }
        case .other(let other):
            switch other {
            case .alternate:
                normalButtonView.isHidden = !normalButtonView.isHidden
                alternateButtonView.isHidden = !alternateButtonView.isHidden
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
    
    @objc func buttonTouchUpOutside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
    }
}


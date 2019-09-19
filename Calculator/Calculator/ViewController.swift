//
//  ViewController.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-09.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import UIKit

enum Button: String {
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
    case decimal = "."
    case equal = "="
    case add = "+"
    case subtract = "-"
    case multiply = "x"
    case divide = "÷"
    case exponent = "^"
    case open = "("
    case close = ")"
    case alternate = "ALT"
    case clear = "CLR"
    case delete = "DEL"
    case answer = "ANS"
    case memory = "MEM"
    case set = "SET"
    
    static func functions() -> [Button] {
        return [.add, .subtract, .multiply, .divide, .exponent]
    }
    static func variables() -> [Button] {
        return [.answer, .memory]
    }
    static func parentheses() -> [Button] {
        return [.open, .close]
    }
    static func numbers() -> [Button] {
        return [.zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine]
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
                case Button.memory.rawValue:
                    return String(memory)
                case "-" + Button.memory.rawValue:
                    return String(-memory)
                case Button.answer.rawValue:
                    return String(answer)
                case "-" + Button.answer.rawValue:
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
            guard let memoryValueDisplayLabel = variableSubviews[Button.memory.rawValue] else {
                return
            }

            memoryValueDisplayLabel.text = "= " + memory.toSimpleNumericString(true) + " "
        }
    }
    var answer: Double = 0 {
        didSet {
            guard let answerValueDisplayLabel = variableSubviews[Button.answer.rawValue] else {
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
        
        let normalButtonLayout: [[Button]] = [[      .zero, .decimal,  .equal,      .add ],
                                              [       .one,     .two,  .three, .subtract ],
                                              [      .four,    .five,    .six, .multiply ],
                                              [     .seven,   .eight,   .nine,   .divide ],
                                              [      .open,   .close, .answer, .exponent ],
                                              [ .alternate,  .delete,    .set,   .memory ]]
        
        let alternateButtonLayout: [[Button]] = [[      .zero, .decimal,  .equal,      .add ],
                                                 [       .one,     .two,  .three, .subtract ],
                                                 [      .four,    .five,    .six, .multiply ],
                                                 [     .seven,   .eight,   .nine,   .divide ],
                                                 [      .open,   .close, .answer, .exponent ],
                                                 [ .alternate,   .clear,    .set,   .memory ]]
        
        assert(normalButtonLayout.count == alternateButtonLayout.count && normalButtonLayout[0] == alternateButtonLayout[0])
        
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
                    button.setTitle(buttonType.rawValue, for: .normal)
                    button.backgroundColor = kInactiveButtonColor
                    button.setTitleColor(layout == alternateButtonLayout && buttonType == .alternate ? kActiveButtonColor : .white, for: .normal)
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
        
        let variableCount: CGFloat = CGFloat(Button.variables().count)
        let variableViewY = valueDisplayLabelY + valueDisplayLabelH + kViewMargin
        let variableViewW = view.frame.width
        
        let variableSubviewW: CGFloat = variableViewW / variableCount
        
        variableView.frame = CGRect(x: 0, y: variableViewY, width: variableViewW, height: variableViewH)
        variableView.isOpaque = true
        variableView.backgroundColor = kInactiveButtonColor
        
        for (index, variable) in Button.variables().enumerated() {
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
              let button: Button = Button(rawValue: buttonText) else {
            return
        }
        
        let expressionCount = expressionList.count
        let lastExpression: String = expressionList[expressionCount - 1]
        
        switch button {
        case .alternate:
            normalButtonView.isHidden = !normalButtonView.isHidden
            alternateButtonView.isHidden = !alternateButtonView.isHidden
        case .memory, .answer:
            if lastExpression.isDouble() && !["0", "-0"].contains(lastExpression) {
                return
            }
            
            fallthrough
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
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
            
            return
        case .equal:
            answer = currentValue
            return
        case .decimal:
            if lastExpression.isInt() {
                expressionList[expressionCount - 1] = lastExpression + buttonText
            }
            
            return
        case .subtract:
            var allowNegationList: [String] = Button.functions().map({$0.rawValue})
            allowNegationList += [Button.open.rawValue]
            allowNegationList += ["-" + Button.open.rawValue]
            
            if expressionList == ["0"] {
                expressionList = ["-0"]
            } else if allowNegationList.contains(lastExpression) {
                expressionList += ["-0"]
            } else if lastExpression.isCloseParen() || lastExpression.isProperDouble() {
                expressionList += [buttonText]
            }
            
            return
        case .add, .multiply, .divide, .exponent:
            if lastExpression.isOpenParen() || !lastExpression.isProperDouble() && !lastExpression.isCloseParen() {
                return
            }
            
            expressionList += [buttonText]
            
            return
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
            
            return
        case .close:
            if !lastExpression.isProperDouble() && !lastExpression.isCloseParen() || parenBalance == 0 {
                return
            }
            
            expressionList += [buttonText]
            parenBalance -= 1
            
            return
        case .clear:
            expressionList = []
            parenBalance = 0
            return
        case .delete:
            parenBalance += lastExpression.isCloseParen() ? 1 : lastExpression.isOpenParen() ? -1 : 0
            
            if lastExpression.isProperDouble() {
                expressionList[expressionCount - 1] = String(lastExpression.dropLast())
            }
            
            // Also catches pesky "" expressions that persist after deleting doubles
            if !expressionList[expressionCount - 1].isProperDouble() {
                expressionList = expressionList.dropLast()
            }
            
            return
        case .set:
            memory = currentValue
            return
        }
    }
    
    @objc func buttonTouchUpOutside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
    }
}


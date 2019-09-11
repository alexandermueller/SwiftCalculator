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
    case clear = "CLR"
    case delete = "DEL"
    case answer = "ANS"
    case memory = "MEM"
    case set = "SET"
}

let kInactiveButtonColor: UIColor = .brown
let kActiveButtonColor: UIColor = .orange
let kViewMargin: CGFloat = 2
let kLabelFontToHeightRatio: CGFloat = 0.33

class ViewController: UIViewController {
    let backgroundView = UIView()
    let textDisplayLabel = UILabel()
    let valueDisplayLabel = UILabel()
    let functionView = UIView()
    let buttonView = UIView()
    
    var functionSubviews: [String : UILabel] = [:]
    
    var currentState: UIControl.State = .normal
    var expressionList: [String] = ["0"] {
        didSet {
            if expressionList.isEmpty {
                expressionList = ["0"]
            }
            
            textDisplayLabel.text = expressionList.joined(separator: " ") + " ="
            currentValue = parseExpression(expressionList).evaluate()
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
            guard let memoryValueDisplayLabel = functionSubviews[Button.memory.rawValue] else {
                return
            }

            memoryValueDisplayLabel.text = "= " + memory.toSimpleNumericString() + " "
        }
    }
    var answer: Double = 0 {
        didSet {
            guard let answerValueDisplayLabel = functionSubviews[Button.answer.rawValue] else {
                return
            }
            
            answerValueDisplayLabel.text = "= " + answer.toSimpleNumericString() + " "
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        backgroundView.frame = view.frame
        backgroundView.backgroundColor = .black
        
        buttonView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        buttonView.isOpaque = false
        
        let buttonLayout: [[Button]] = [[  .zero, .decimal,  .equal,      .add ],
                                        [   .one,     .two,  .three, .subtract ],
                                        [  .four,    .five,    .six, .multiply ],
                                        [ .seven,   .eight,   .nine,   .divide ],
                                        [  .open,   .close, .answer, .exponent ],
                                        [ .clear,  .delete,    .set,   .memory ]]
        
        let buttonW = buttonView.frame.width / CGFloat(buttonLayout[0].count)
        let buttonH = buttonView.frame.height / CGFloat(buttonLayout.count)
        var buttonPointSize: CGFloat = 0
        
        for (rowIndex, row) in buttonLayout.enumerated() {
            let buttonY = buttonView.frame.height - CGFloat(rowIndex + 1) * buttonH
            
            for (columnIndex, buttonType) in row.enumerated() {
                let buttonX = CGFloat(columnIndex % 4) * buttonW
                
                let button = UIButton()
                button.frame = CGRect(x: buttonX, y: buttonY, width: buttonW, height: buttonH)
                button.setTitle(buttonType.rawValue, for: .normal)
                button.backgroundColor = kInactiveButtonColor
                button.addTarget(self, action: #selector(buttonTouchDown), for: UIControl.Event.touchDown)
                button.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControl.Event.touchUpInside)
                button.addTarget(self, action: #selector(buttonTouchUpOutside), for: UIControl.Event.touchUpOutside)
                
                buttonView.addSubview(button)
                
                if let label = button.titleLabel, buttonPointSize == 0 {
                    buttonPointSize = label.font.pointSize
                }
            }
        }
        
        let textDisplayLabelY: CGFloat = 35
        let textDisplayLabelH: CGFloat = 99
        
        textDisplayLabel.frame = CGRect(x: 0, y: textDisplayLabelY, width: view.frame.width, height: textDisplayLabelH)
        textDisplayLabel.backgroundColor = .white
        textDisplayLabel.textColor = .black
        textDisplayLabel.textAlignment = .right
        textDisplayLabel.adjustsFontSizeToFitWidth = true
        textDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: textDisplayLabelH * kLabelFontToHeightRatio)
        
        let functionViewH = buttonH 
        let valueDisplayLabelY = textDisplayLabelY + textDisplayLabelH + kViewMargin
        let valueDisplayLabelH = view.frame.height * 0.5 - valueDisplayLabelY - functionViewH - kViewMargin
        
        valueDisplayLabel.frame = CGRect(x: 0, y: valueDisplayLabelY, width: view.frame.width, height: valueDisplayLabelH)
        valueDisplayLabel.backgroundColor = .white
        valueDisplayLabel.textColor = .brown
        valueDisplayLabel.textAlignment = .right
        valueDisplayLabel.adjustsFontSizeToFitWidth = true
        valueDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: valueDisplayLabelH * kLabelFontToHeightRatio)
        
        buttonView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        buttonView.isOpaque = false
        
        expressionList = ["0"]
        
        let functions: [Button] = [.memory, .answer]
        let functionCount: CGFloat = CGFloat(functions.count)
        
        let functionViewY = valueDisplayLabelY + valueDisplayLabelH + kViewMargin
        let functionViewW = view.frame.width
        
        let functionSubviewW: CGFloat = functionViewW / functionCount
        
        functionView.frame = CGRect(x: 0, y: functionViewY, width: functionViewW, height: functionViewH)
        functionView.isOpaque = true
        functionView.backgroundColor = kInactiveButtonColor
        
        for (index, function) in functions.enumerated() {
            let functionSubviewX: CGFloat = CGFloat(index) * functionViewW / functionCount

            let functionSubview = UIView()
            functionSubview.frame = CGRect(x: functionSubviewX, y: 0, width: functionSubviewW, height: functionViewH)
            functionSubview.isOpaque = false
            
            let functionTitleLabel = UILabel()
            functionTitleLabel.frame = CGRect(x: 0, y: 0, width: buttonW, height: buttonH)
            functionTitleLabel.backgroundColor = kInactiveButtonColor
            functionTitleLabel.textColor = kActiveButtonColor
            functionTitleLabel.textAlignment = .center
            functionTitleLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: buttonPointSize)
            functionTitleLabel.text = function.rawValue
            
            let functionValueDisplayLabel = UILabel()
            functionValueDisplayLabel.frame = CGRect(x: buttonW + 1, y: 0, width: functionSubviewW - buttonW, height: buttonH)
            functionValueDisplayLabel.backgroundColor = kInactiveButtonColor
            functionValueDisplayLabel.textColor = kActiveButtonColor
            functionValueDisplayLabel.textAlignment = .center
            functionValueDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: buttonPointSize)
            
            functionSubviews[function.rawValue] = functionValueDisplayLabel
            
            functionSubview.addSubview(functionTitleLabel)
            functionSubview.addSubview(functionValueDisplayLabel)
            functionView.addSubview(functionSubview)
        }
        
        memory = 0
        answer = 0
        
        view.addSubview(backgroundView)
        view.addSubview(textDisplayLabel)
        view.addSubview(valueDisplayLabel)
        view.addSubview(functionView)
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
        case .memory, .answer:
            if lastExpression.isDouble() && !["0", "-0"].contains(lastExpression) {
                return
            }
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            if lastExpression.isCloseParen() || lastExpression.isAFunction() {
                return
            }
            
            if lastExpression.isDouble() {
                var newExpression: String {
                    switch lastExpression {
                    case "0":
                        return buttonText
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
            var allowNegationList: [String] = [Button.add, Button.subtract, Button.multiply, Button.divide, Button.exponent, Button.open].map({$0.rawValue})
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
            if expressionList == ["0"] || lastExpression == "-0" {
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


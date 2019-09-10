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

class ViewController: UIViewController {
    let backgroundView = UIView()
    let textDisplayLabel = UILabel()
    let valueDisplayLabel = UILabel()
    let buttonView = UIView()
    
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
    var memory: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        backgroundView.frame = view.frame
        backgroundView.backgroundColor = .black
        
        let textDisplayLabelY: CGFloat = 35
        let textDisplayLabelH: CGFloat = 99
        
        textDisplayLabel.frame = CGRect(x: 0, y: textDisplayLabelY, width: view.frame.width, height: textDisplayLabelH)
        textDisplayLabel.backgroundColor = .white
        textDisplayLabel.textColor = .black
        textDisplayLabel.textAlignment = .right
        textDisplayLabel.adjustsFontSizeToFitWidth = true
        textDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: textDisplayLabelH * 0.33)
        
        let valueDisplayLabelY = textDisplayLabelY + textDisplayLabelH + 2
        let valueDisplayLabelH = view.frame.height * 0.5 - valueDisplayLabelY - 2
        
        valueDisplayLabel.frame = CGRect(x: 0, y: valueDisplayLabelY, width: view.frame.width, height: valueDisplayLabelH)
        valueDisplayLabel.backgroundColor = .white
        valueDisplayLabel.textColor = .brown
        valueDisplayLabel.textAlignment = .right
        textDisplayLabel.adjustsFontSizeToFitWidth = true
        valueDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: valueDisplayLabelH * 0.33)
        
        buttonView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        buttonView.isOpaque = false
        
        expressionList = ["0"]
        
        let buttonLayout: [[Button]] = [[  .zero, .decimal,  .equal,      .add ],
                                        [   .one,     .two,  .three, .subtract ],
                                        [  .four,    .five,    .six, .multiply ],
                                        [ .seven,   .eight,   .nine,   .divide ],
                                        [  .open,   .close, .answer, .exponent ],
                                        [ .clear,  .delete,    .set,   .memory ]]
        
        let buttonW = buttonView.frame.width / 4
        let buttonH = buttonView.frame.height / 6
        
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
            }
        }
        
        view.addSubview(backgroundView)
        view.addSubview(textDisplayLabel)
        view.addSubview(valueDisplayLabel)
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
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            if lastExpression.isCloseParen() {
                return
            }
            
            if lastExpression.isDouble() {
                expressionList[expressionCount - 1] = lastExpression == "0" ? button.rawValue : lastExpression + button.rawValue
            } else {
                expressionList += [button.rawValue]
            }
            
            return
        case .equal:
            expressionList = [currentValue.toSimpleNumericString()]
            return
        case .decimal:
            if lastExpression.isInt() {
                expressionList[expressionCount - 1] = lastExpression + button.rawValue
            }
            
            return
        case .add, .subtract, .multiply, .divide, .exponent:
            if lastExpression.isOpenParen() || !lastExpression.isProperDouble() && !lastExpression.isCloseParen(){
                return
            }
            
            expressionList += [button.rawValue]
            
            return
        case .open:
            if expressionList == ["0"] {
                expressionList = [buttonText]
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
        case .memory, .answer:
            return
        }
    }
    
    @objc func buttonTouchUpOutside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
    }
}


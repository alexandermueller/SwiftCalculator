//
//  ViewController.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-09.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import UIKit

let kInactiveButtonColor: UIColor = .brown
let kActiveButtonColor: UIColor = .orange
let kViewMargin: CGFloat = 2
let kLabelFontToHeightRatio: CGFloat = 0.33

class ViewController: UIViewController {
    let viewModel = ViewModel()
    let backgroundView = UIView()
    let textDisplayLabel = UILabel()
    let valueDisplayLabel = UILabel()
    let variableView = UIView()
    let buttonView = UIView()
    let normalButtonView = UIView()
    let alternateButtonView = UIView()
    
    var variableSubviews: [String : UILabel] = [:]
    var currentState: UIControl.State = .normal
    
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
                                              [ .parenthesis(.open), .parenthesis(.close),   .function(.root), .function(.exponent) ],
                                              [  .other(.alternate),       .other(.clear),    .other(.delete),   .variable(.answer) ]]
        
        let alternateButtonLayout: [[Button]] = [[       .digit(.zero),  .modifier(.decimal),      .setter(.set),      .function(.add) ],
                                                 [        .digit(.one),         .digit(.two),     .digit(.three), .function(.subtract) ],
                                                 [       .digit(.four),        .digit(.five),       .digit(.six), .function(.multiply) ],
                                                 [      .digit(.seven),       .digit(.eight),      .digit(.nine),   .function(.divide) ],
                                                 [ .parenthesis(.open), .parenthesis(.close),   .function(.root), .function(.exponent) ],
                                                 [  .other(.alternate),       .other(.clear),    .other(.delete),   .variable(.memory) ]]
        
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
        textDisplayLabel.text = "0 ="
        
        let variableViewH = buttonH
        let valueDisplayLabelY = textDisplayLabelY + textDisplayLabelH + kViewMargin
        let valueDisplayLabelH = view.frame.height * 0.5 - valueDisplayLabelY - variableViewH - kViewMargin
        
        valueDisplayLabel.frame = CGRect(x: 0, y: valueDisplayLabelY, width: view.frame.width, height: valueDisplayLabelH)
        valueDisplayLabel.backgroundColor = .white
        valueDisplayLabel.textColor = .brown
        valueDisplayLabel.textAlignment = .right
        valueDisplayLabel.adjustsFontSizeToFitWidth = true
        valueDisplayLabel.font = UIFont.init(name: textDisplayLabel.font.fontName, size: valueDisplayLabelH * kLabelFontToHeightRatio)
        valueDisplayLabel.text = "0"
        
        buttonView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        buttonView.isOpaque = false
        
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
            variableValueDisplayLabel.adjustsFontSizeToFitWidth = true
            variableValueDisplayLabel.text = "= 0 "
            
            variableSubviews[variable.rawValue] = variableValueDisplayLabel
            
            variableSubview.addSubview(variableTitleLabel)
            variableSubview.addSubview(variableValueDisplayLabel)
            variableView.addSubview(variableSubview)
        }
        
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
        
        viewModel.buttonPressed(button)
        
        textDisplayLabel.text = viewModel.expressionList.joined(separator: " ") + " ="
        valueDisplayLabel.text = viewModel.currentValue.toSimpleNumericString(for: .fullDisplay) // TODO: This might need some fine-tuning (was false before)
        
        normalButtonView.isHidden = viewModel.buttonViewMode != .normal
        alternateButtonView.isHidden = viewModel.buttonViewMode != .alternate
        
        if let memoryValueDisplayLabel = variableSubviews[Variable.memory.rawValue] {
            memoryValueDisplayLabel.text = "= " + viewModel.memory.toSimpleNumericString(for: .buttonDisplay) + " "
        }
        
        if let answerValueDisplayLabel = variableSubviews[Variable.answer.rawValue] {
            answerValueDisplayLabel.text = "= " + viewModel.answer.toSimpleNumericString(for: .buttonDisplay) + " "
        }
    }
    
    @objc func buttonTouchUpOutside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
    }
}


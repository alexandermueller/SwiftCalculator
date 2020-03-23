//
//  ViewController.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-09.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum ButtonViewMode {
    case normal
    case alternate
}

let kInactiveButtonColor: UIColor = .brown
let kActiveButtonColor: UIColor = .orange
let kViewMargin: CGFloat = 2
let kLabelFontToHeightRatio: CGFloat = 0.33

class ViewController: UIViewController {
    private let viewModel: ViewModel
    private let buttonViewModeSubject = BehaviorSubject<ButtonViewMode>(value: .normal)
    private let memorySubject = BehaviorSubject<Double>(value: 0)
    private let answerSubject = BehaviorSubject<Double>(value: 0)
    private let expressionTextSubject = BehaviorSubject<String>(value: "0")
    private let currentValueSubject = BehaviorSubject<Double>(value: 0)
    private let buttonPressSubject = PublishSubject<Button>()
    
    private let bag = DisposeBag()
    private let backgroundView = UIView()
    private let textDisplayLabel = UILabel()
    private let textDisplayColourSubject = BehaviorSubject<UIColor>(value: .gray)
    private let valueDisplayLabel = UILabel()
    private let variableView = UIView()
    private let buttonView = UIView()
    private let normalButtonView = UIView()
    private let alternateButtonView = UIView()

    private var variableSubviews: [String : UILabel] = [:]
    private var currentState: UIControl.State = .normal
    
     required init?(coder aDecoder: NSCoder) {
        viewModel = ViewModel(expressionTextSubject: expressionTextSubject,
                              currentValueSubject: currentValueSubject,
                              memorySubject: memorySubject,
                              answerSubject: answerSubject,
                              buttonViewModeSubject: buttonViewModeSubject,
                              buttonPressSubject: buttonPressSubject,
                              textDisplayColourSubject: textDisplayColourSubject,
                              bag: bag)
        
        viewModel.startStateMachine()
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        backgroundView.frame = view.frame
        backgroundView.backgroundColor = .black
        
        buttonView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        buttonView.isOpaque = false
        
        let normalButtonLayout: [[Button]] = [[       .digit(.zero),  .modifier(.decimal),          .other(.equal),      .function(.middle(.add)) ],
                                              [        .digit(.one),         .digit(.two),          .digit(.three), .function(.middle(.subtract)) ],
                                              [       .digit(.four),        .digit(.five),            .digit(.six), .function(.middle(.multiply)) ],
                                              [      .digit(.seven),       .digit(.eight),           .digit(.nine),   .function(.middle(.divide)) ],
                                              [ .parenthesis(.open), .parenthesis(.close), .function(.left(.sqrt)), .function(.middle(.exponent)) ],
                                              [  .other(.alternate),       .other(.clear),         .other(.delete),            .variable(.answer) ]]
        
        let alternateButtonLayout: [[Button]] = [[       .digit(.zero),  .modifier(.decimal),               .other(.set),        .function(.left(.sum)) ],
                                                 [        .digit(.one),         .digit(.two),             .digit(.three),        .function(.left(.abs)) ],
                                                 [       .digit(.four),        .digit(.five),               .digit(.six), .function(.right(.factorial)) ],
                                                 [      .digit(.seven),       .digit(.eight),              .digit(.nine),        .function(.left(.inv)) ],
                                                 [ .parenthesis(.open), .parenthesis(.close), .function(.right(.square)),   .function(.middle(.modulo)) ],
                                                 [  .other(.alternate),       .other(.clear),            .other(.delete),            .variable(.memory) ]]
        
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
        
        textDisplayColourSubject.subscribe(onNext: { [unowned self] colour in
            self.textDisplayLabel.textColor = colour
        }).disposed(by: bag)
        
        expressionTextSubject.subscribe(onNext: { [unowned self] expression in
            self.textDisplayLabel.text = expression + "="
        }).disposed(by: bag)
        
        currentValueSubject.subscribe(onNext: { [unowned self] currentValue in
            self.valueDisplayLabel.text = currentValue.toSimpleNumericString(for: .fullDisplay)
        }).disposed(by: bag)
        
        buttonViewModeSubject.subscribe(onNext: { [unowned self] buttonViewMode in
            self.normalButtonView.isHidden = buttonViewMode != .normal
            self.alternateButtonView.isHidden = buttonViewMode != .alternate
        }).disposed(by: bag)
        
        memorySubject.subscribe(onNext: { [unowned self] memory in
            if let memoryValueDisplayLabel = self.variableSubviews[Variable.memory.rawValue] {
                memoryValueDisplayLabel.text = "= " + memory.toSimpleNumericString(for: .buttonDisplay) + " "
            }
        }).disposed(by: bag)
        
        answerSubject.subscribe(onNext: { [unowned self] answer in
            if let answerValueDisplayLabel = self.variableSubviews[Variable.answer.rawValue] {
                answerValueDisplayLabel.text = "= " + answer.toSimpleNumericString(for: .buttonDisplay) + " "
            }
        }).disposed(by: bag)
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
        
        buttonPressSubject.onNext(button)
    }
    
    @objc func buttonTouchUpOutside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
    }
}


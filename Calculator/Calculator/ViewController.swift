//
//  ViewController.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-09.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import UIKit
import RxSwift

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
    private let memorySubject = BehaviorSubject<MaxPrecisionNumber>(value: 0)
    private let answerSubject = BehaviorSubject<MaxPrecisionNumber>(value: 0)
    private let expressionTextSubject = BehaviorSubject<String>(value: "0")
    private let currentValueSubject = BehaviorSubject<MaxPrecisionNumber>(value: 0)
    private let buttonPressSubject = PublishSubject<Button>()
    
    private let bag = DisposeBag()
    private let backgroundView = UIView()
    private let textDisplayLabel = UILabel()
    private let textDisplayColourSubject = BehaviorSubject<UIColor>(value: .gray)
    private let valueDisplayLabel = UILabel()
    private let variablesView = UIView()
    private let buttonsView = UIView()
    private let normalButtonsView = UIView()
    private let alternateButtonsView = UIView()

    private var variableViewsDict: [String : UILabel] = [:]
    private var currentState: UIControl.State = .normal
    
    private let normalButtonsLayout: [[Button]] = [[       .digit(.zero),  .modifier(.decimal),          .other(.equal),      .function(.middle(.add)) ],
                                                   [        .digit(.one),         .digit(.two),          .digit(.three), .function(.middle(.subtract)) ],
                                                   [       .digit(.four),        .digit(.five),            .digit(.six), .function(.middle(.multiply)) ],
                                                   [      .digit(.seven),       .digit(.eight),           .digit(.nine),   .function(.middle(.divide)) ],
                                                   [ .parenthesis(.open), .parenthesis(.close), .function(.left(.sqrt)), .function(.middle(.exponent)) ],
                                                   [  .other(.alternate),       .other(.clear),         .other(.delete),            .variable(.answer) ]]
            
    private let alternateButtonsLayout: [[Button]] = [[       .digit(.zero),  .modifier(.decimal),           .other(.set),        .function(.left(.sum)) ],
                                                      [        .digit(.one),         .digit(.two),         .digit(.three),        .function(.left(.abs)) ],
                                                      [       .digit(.four),        .digit(.five),           .digit(.six), .function(.right(.factorial)) ],
                                                      [      .digit(.seven),       .digit(.eight),          .digit(.nine),   .function(.middle(.modulo)) ],
                                                      [ .parenthesis(.open), .parenthesis(.close), .function(.left(.inv)),    .function(.right(.square)) ],
                                                      [  .other(.alternate),       .other(.clear),        .other(.delete),            .variable(.memory) ]]
    
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
    
    override func viewDidLayoutSubviews() {
        assert(normalButtonsLayout.count == alternateButtonsLayout.count && normalButtonsLayout[0].count == alternateButtonsLayout[0].count)
        
        backgroundView.frame = view.frame
        buttonsView.frame = CGRect(x: 0, y: view.frame.height * 0.5, width: view.frame.width, height: view.frame.height * 0.5)
        
        let rows = normalButtonsLayout.count
        let columns = normalButtonsLayout[0].count
        let buttonW = buttonsView.frame.width / CGFloat(columns)
        let buttonH = buttonsView.frame.height / CGFloat(rows)
        
        // TODO: Set a MIN WIDTH AND HEIGHT for the main view on MacOS!!!
        
        for buttonsSubview in [normalButtonsView, alternateButtonsView] {
            buttonsSubview.frame = CGRect(x: 0, y: 0, width: buttonsView.frame.width, height: buttonsView.frame.height)
            
            for (index, buttonSubview) in buttonsSubview.subviews.enumerated() {
                let rowIndex = index / columns
                let columnIndex = index % columns
                let buttonY = buttonsView.frame.height - CGFloat(rowIndex + 1) * buttonH
                let buttonX = CGFloat(columnIndex) * buttonW
                
                buttonSubview.frame = CGRect(x: buttonX, y: buttonY, width: buttonW, height: buttonH)
                
                if let button = buttonSubview as? UIButton, let label = button.titleLabel {
                    label.font = UIFont.systemFont(ofSize: buttonH * kLabelFontToHeightRatio)
                }
            }
        }
        
        let textDisplayLabelH: CGFloat = buttonH * 1.5 // TODO: Something is messing with the text label centering on MacOS
        textDisplayLabel.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: textDisplayLabelH)
        textDisplayLabel.font = UIFont.systemFont(ofSize: textDisplayLabelH * kLabelFontToHeightRatio)
        
        let variablesViewH = buttonH
        let valueDisplayLabelY = textDisplayLabelH + kViewMargin
        let valueDisplayLabelH = view.frame.height * 0.5 - valueDisplayLabelY - variablesViewH - kViewMargin
        valueDisplayLabel.frame = CGRect(x: 0, y: valueDisplayLabelY, width: view.frame.width, height: valueDisplayLabelH)
        valueDisplayLabel.font = UIFont.systemFont(ofSize: valueDisplayLabelH * kLabelFontToHeightRatio)
        
        let variableCount: CGFloat = CGFloat(Variable.allCases.count)
        let variablesViewY = valueDisplayLabelY + valueDisplayLabelH + kViewMargin
        let variablesViewW = view.frame.width
        let variableViewW = variablesViewW / variableCount
        variablesView.frame = CGRect(x: 0, y: variablesViewY, width: variablesViewW, height: variablesViewH)
        
        for (index, variableView) in variablesView.subviews.enumerated() {
            let variableViewX: CGFloat = CGFloat(index) * variablesViewW / variableCount

            variableView.frame = CGRect(x: variableViewX, y: 0, width: variableViewW, height: variablesViewH)
            
            if let variableTitleLabel = variableView.subviews[0] as? UILabel {
                variableTitleLabel.frame = CGRect(x: 0, y: 0, width: buttonW, height: buttonH)
                variableTitleLabel.font = UIFont.systemFont(ofSize: buttonH * kLabelFontToHeightRatio)
            }
            
            if let variableValueDisplayLabel = variableView.subviews[1] as? UILabel {
                variableValueDisplayLabel.frame = CGRect(x: buttonW, y: 0, width: variableViewW - buttonW, height: buttonH)
                variableValueDisplayLabel.font = UIFont.systemFont(ofSize: buttonH * kLabelFontToHeightRatio)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(normalButtonsLayout.count == alternateButtonsLayout.count && normalButtonsLayout[0].count == alternateButtonsLayout[0].count)
        
        backgroundView.backgroundColor = .black
        buttonsView.isOpaque = false
                
        for (layout, buttonsSubview, isVisible) in [(normalButtonsLayout, normalButtonsView, true), (alternateButtonsLayout, alternateButtonsView, false)] {
            buttonsSubview.isOpaque = false
            buttonsSubview.isHidden = !isVisible
            
            for row in layout {
                for buttonType in row {
                    let button = UIButton()
                    button.setTitle(buttonType.rawValue(), for: .normal)
                    button.backgroundColor = kInactiveButtonColor
                    button.setTitleColor(layout == alternateButtonsLayout && buttonType == .other(.alternate) ? kActiveButtonColor : .white, for: .normal)
                    button.addTarget(self, action: #selector(buttonTouchDown), for: UIControl.Event.touchDown)
                    button.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControl.Event.touchUpInside)
                    button.addTarget(self, action: #selector(buttonTouchUpOutside), for: UIControl.Event.touchUpOutside)
                    
                    buttonsSubview.addSubview(button)
                }
            }
            
            buttonsView.addSubview(buttonsSubview)
        }
        
        textDisplayLabel.backgroundColor = .white
        textDisplayLabel.textColor = .black
        textDisplayLabel.textAlignment = .right
        textDisplayLabel.adjustsFontSizeToFitWidth = true
        textDisplayLabel.text = "0 ="
        
        valueDisplayLabel.backgroundColor = .white
        valueDisplayLabel.textColor = .brown
        valueDisplayLabel.textAlignment = .right
        valueDisplayLabel.adjustsFontSizeToFitWidth = true
        valueDisplayLabel.text = "0"
        
        buttonsView.isOpaque = false
        
        variablesView.backgroundColor = kInactiveButtonColor
        
        for variable in Variable.allCases {
            let variableView = UIView()
            variableView.isOpaque = false
            
            let variableTitleLabel = UILabel()
            variableTitleLabel.textColor = kActiveButtonColor
            variableTitleLabel.textAlignment = .center
            variableTitleLabel.text = variable.rawValue
            variableTitleLabel.isOpaque = false
            
            let variableValueDisplayLabel = UILabel()
            variableValueDisplayLabel.textColor = kActiveButtonColor
            variableValueDisplayLabel.textAlignment = .center
            variableValueDisplayLabel.adjustsFontSizeToFitWidth = true
            variableValueDisplayLabel.text = "= 0 "
            variableValueDisplayLabel.isOpaque = false

            variableViewsDict[variable.rawValue] = variableValueDisplayLabel

            variableView.addSubview(variableTitleLabel)
            variableView.addSubview(variableValueDisplayLabel)
            variablesView.addSubview(variableView)
        }
        
        view.addSubview(backgroundView)
        view.addSubview(textDisplayLabel)
        view.addSubview(valueDisplayLabel)
        view.addSubview(variablesView)
        view.addSubview(buttonsView)
        
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
            self.normalButtonsView.isHidden = buttonViewMode != .normal
            self.alternateButtonsView.isHidden = buttonViewMode != .alternate
        }).disposed(by: bag)
        
        memorySubject.subscribe(onNext: { [unowned self] memory in
            if let memoryValueDisplayLabel = self.variableViewsDict[Variable.memory.rawValue] {
                memoryValueDisplayLabel.text = "= " + memory.toSimpleNumericString(for: .buttonDisplay) + " "
            }
        }).disposed(by: bag)
        
        answerSubject.subscribe(onNext: { [unowned self] answer in
            if let answerValueDisplayLabel = self.variableViewsDict[Variable.answer.rawValue] {
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


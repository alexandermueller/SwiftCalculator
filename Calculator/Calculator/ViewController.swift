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
let kAspectRatioThreshold: CGFloat = 0.75

class ViewController : UIViewController, UIPopoverPresentationControllerDelegate {
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
    private let fullButtonsView = UIView()
    
    private var showFullButtonsView = false
    private var buttonRows = 0
    private var buttonColumns = 0
    
    private var variableViewsDict: [String : UILabel] = [:]
    
    // TODO: - Abolish this weird split system using popovers instead of a dedicated ALT button.
    //       - Make keyboard on macs work as input, ie delete == delete, etc etc.
    
    private let normalButtonsLayout: [[Button]] = [[  .other(.alternate),   .variable(.answer),      .variable(.memory),               .other(.delete) ],
                                                   [ .parenthesis(.open), .parenthesis(.close), .function(.left(.sqrt)), .function(.middle(.exponent)) ],
                                                   [      .digit(.seven),       .digit(.eight),           .digit(.nine),   .function(.middle(.divide)) ],
                                                   [       .digit(.four),        .digit(.five),            .digit(.six), .function(.middle(.multiply)) ],
                                                   [        .digit(.one),         .digit(.two),          .digit(.three), .function(.middle(.subtract)) ],
                                                   [       .digit(.zero),  .modifier(.decimal),          .other(.equal),      .function(.middle(.add)) ]].reversed()
            
    private let alternateButtonsLayout: [[Button]] = [[  .other(.alternate),   .variable(.answer),     .variable(.memory),               .other(.delete) ],
                                                      [ .parenthesis(.open), .parenthesis(.close), .function(.left(.inv)),    .function(.right(.square)) ],
                                                      [      .digit(.seven),       .digit(.eight),          .digit(.nine),   .function(.middle(.modulo)) ],
                                                      [       .digit(.four),        .digit(.five),           .digit(.six), .function(.right(.factorial)) ],
                                                      [        .digit(.one),         .digit(.two),         .digit(.three),        .function(.left(.abs)) ],
                                                      [       .digit(.zero),  .modifier(.decimal),           .other(.set),        .function(.left(.sum)) ]].reversed()
    
    private let fullButtonsLayout: [[Button]] = [[  .variable(.answer),   .variable(.memory),            .other(.set),               .other(.delete),        .function(.left(.inv)) ],
                                                 [ .parenthesis(.open), .parenthesis(.close), .function(.left(.sqrt)), .function(.middle(.exponent)),    .function(.right(.square)) ],
                                                 [      .digit(.seven),       .digit(.eight),           .digit(.nine),   .function(.middle(.divide)),   .function(.middle(.modulo)) ],
                                                 [       .digit(.four),        .digit(.five),            .digit(.six), .function(.middle(.multiply)), .function(.right(.factorial)) ],
                                                 [        .digit(.one),         .digit(.two),          .digit(.three), .function(.middle(.subtract)),        .function(.left(.abs)) ],
                                                 [       .digit(.zero),  .modifier(.decimal),          .other(.equal),      .function(.middle(.add)),        .function(.left(.sum)) ]].reversed()
    
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

        assert(normalButtonsLayout.count == alternateButtonsLayout.count && normalButtonsLayout[0].count == alternateButtonsLayout[0].count)
        
        backgroundView.backgroundColor = .black
        buttonsView.isOpaque = false
        
        for (layout, buttonsSubview) in [(normalButtonsLayout, normalButtonsView), (alternateButtonsLayout, alternateButtonsView), (fullButtonsLayout, fullButtonsView)] {
            buttonsSubview.isOpaque = false
            
            for row in layout {
                for buttonType in row {
                    let button = UIButton()
                    
                    button.setTitle(buttonType.buttonDisplayValue(), for: .normal)
                    button.setTitle(buttonType.rawValue(), for: .reserved)
                    button.backgroundColor = kInactiveButtonColor
                    button.setTitleColor(layout == alternateButtonsLayout && buttonType == .other(.alternate) ? kActiveButtonColor : .white, for: .normal)
                    button.addTarget(self, action: #selector(buttonTouchDown), for: UIControl.Event.touchDown)
                    button.addTarget(self, action: #selector(buttonTouchUpInside), for: UIControl.Event.touchUpInside)
                    button.addTarget(self, action: #selector(buttonTouchUpOutside), for: UIControl.Event.touchUpOutside)
                    button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(buttonLongPressed)))
                    
                    buttonsSubview.addSubview(button)
                }
            }
            
            buttonsView.addSubview(buttonsSubview)
        }
        
        updateButtonLayout()
        
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

        redrawSubviews(with: view.frame)
        
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        showFullButtonsView = size.width > size.height * kAspectRatioThreshold
        updateButtonLayout()
        redrawSubviews(with: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }
    
    // MARK: - Redrawing Functions:
    
    func updateButtonLayout() {
        assert(Thread.isMainThread)
        
        fullButtonsView.isHidden = !showFullButtonsView
        buttonRows = (!showFullButtonsView ? normalButtonsLayout : fullButtonsLayout).count
        buttonColumns = (!showFullButtonsView ? normalButtonsLayout[0] : fullButtonsLayout[0]).count
    }
    
    func redrawSubviews(with viewFrame: CGRect) {
        assert(Thread.isMainThread)
        assert(normalButtonsLayout.count == alternateButtonsLayout.count && normalButtonsLayout[0].count == alternateButtonsLayout[0].count)
        
        backgroundView.frame = viewFrame
        buttonsView.frame = CGRect(x: 0, y: viewFrame.height * 0.5, width: viewFrame.width, height: viewFrame.height * 0.5)

        let buttonW = buttonsView.frame.width / CGFloat(buttonColumns)
        let buttonH = buttonsView.frame.height / CGFloat(buttonRows)
                
        // TODO: Set a MIN WIDTH AND HEIGHT for the main view on MacOS!!!
        
        for buttonsSubview in [normalButtonsView, alternateButtonsView, fullButtonsView] {
            buttonsSubview.frame = CGRect(x: 0, y: 0, width: buttonsView.frame.width, height: buttonsView.frame.height)
            
            for (index, buttonSubview) in buttonsSubview.subviews.enumerated() {
                let rowIndex = index / buttonColumns
                let columnIndex = index % buttonColumns
                let buttonY = buttonsView.frame.height - CGFloat(rowIndex + 1) * buttonH
                let buttonX = CGFloat(columnIndex) * buttonW
                
                buttonSubview.frame = CGRect(x: buttonX, y: buttonY, width: buttonW, height: buttonH)
                
                if let button = buttonSubview as? UIButton, let label = button.titleLabel {
                    label.font = UIFont.systemFont(ofSize: buttonH * kLabelFontToHeightRatio)
                }
            }
        }
        
        let textDisplayLabelH: CGFloat = buttonH * 1.5 // TODO: Something is messing with the text label centering on MacOS
        textDisplayLabel.frame = CGRect(x: 0, y: 0, width: viewFrame.width, height: textDisplayLabelH)
        textDisplayLabel.font = UIFont.systemFont(ofSize: textDisplayLabelH * kLabelFontToHeightRatio)
        
        let variablesViewH = buttonH
        let valueDisplayLabelY = textDisplayLabelH + kViewMargin
        let valueDisplayLabelH = viewFrame.height * 0.5 - valueDisplayLabelY - variablesViewH - kViewMargin
        valueDisplayLabel.frame = CGRect(x: 0, y: valueDisplayLabelY, width: viewFrame.width, height: valueDisplayLabelH)
        valueDisplayLabel.font = UIFont.systemFont(ofSize: valueDisplayLabelH * kLabelFontToHeightRatio)
        
        let variableCount: CGFloat = CGFloat(Variable.allCases.count)
        let variablesViewY = valueDisplayLabelY + valueDisplayLabelH + kViewMargin
        let variablesViewW = viewFrame.width
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
    
    // MARK: - Button Touch Events:
    
    @objc func buttonTouchDown(sender: UIButton!) {
        sender.backgroundColor = kActiveButtonColor
    }
    
    @objc func buttonTouchUpInside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
        
        guard let rawButtonText: String = sender.title(for: .reserved),
              let button: Button = Button.from(rawValue: rawButtonText) else {
            return
        }
        
        buttonPressSubject.onNext(button)
    }
    
    @objc func buttonTouchUpOutside(sender: UIButton!) {
        sender.backgroundColor = kInactiveButtonColor
    }
    
    @objc func buttonLongPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let button = gestureRecognizer.view as? UIButton else {
            return
        }
        
        if gestureRecognizer.state == .began {
            // TODO: Timed animation showing a filling bubble on the button,
            //       so that people know they're about to yeet their entire equation??
            
            switch Button.from(rawValue: button.title(for: .normal) ?? "") {
            case .other(.delete):
                buttonPressSubject.onNext(.other(.clear))
                return
            case .other(.equal):
                buttonPressSubject.onNext(.other(.set))
                return
            default:
                break
            }
//            TODO: Finish this in another release.
//            let vc = ButtonPopoverViewController()
//            vc.preferredContentSize = button.frame.size
//            vc.modalPresentationStyle = .popover
//
//            if let pres = vc.presentationController {
//                pres.delegate = self
//            }
//
//            self.present(vc, animated: true)
//
//            if let pop = vc.popoverPresentationController {
//                pop.sourceView = button
//                pop.sourceRect = button.bounds
//            }
        } else if gestureRecognizer.state == .ended {
            buttonTouchUpOutside(sender: button)
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate Implementation:
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
     
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
     
    }
     
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

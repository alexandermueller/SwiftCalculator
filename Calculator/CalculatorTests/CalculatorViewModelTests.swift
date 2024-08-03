//
//  CalculatorViewModelTests.swift
//  Swift CalculatorTests
//
//  Created by Alexander Mueller on 01.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import Swift_Calculator

class CalculatorViewModelTests: UnitTestSuite {
    func evaluateTransferFunction(
        setUp: ((CalculatorViewModel) -> Void)? = nil,
        expectedExpressionStateFor: (CalculatorViewModel) -> CalculatorViewModel.ExpressionState
    ) {
        let viewModel = CalculatorViewModel()

        for button in Button.allCases {
            if button.isOther {
                continue
            }

            viewModel.goToZero()
            setUp?(viewModel)
            viewModel.buttonPressed = button

            XCTAssertEqual(viewModel.currentExpressionState, expectedExpressionStateFor(viewModel), "\"\(button.rawValue)\"")
        }
    }

    func test_goToZero_transferFunction() {
        evaluateTransferFunction { viewModel in
            switch viewModel.modifiedButtonPressed {
            case .digit:
                .properNumber
            case .modifier:
                .modifiedNumber
            case .parenthesis(.open):
                .openParenthesis
            case .function(.left):
                .leftFunction
            case .function(.middle):
                .middleFunction
            case .function(.right):
                .rightFunction
            case .variable:
                .variable
            default:
                .zero
            }
        }
    }

    func test_goToProperNumber_transferFunction() {
        evaluateTransferFunction { viewModel in
            viewModel.simulate(
                pressedButtonCombo: [
                    .parenthesis(.open),
                    .digit(.one)
                ]
            )
        } expectedExpressionStateFor: { viewModel in
            return switch viewModel.modifiedButtonPressed {
            case .digit:
                .properNumber
            case .modifier:
                if let lastElement = viewModel.expressionElements.last, lastElement.isInteger() {
                    .properNumber
                } else {
                    .modifiedNumber
                }
            case .parenthesis(.close):
                .closeParenthesis
            case .function(.middle):
                .middleFunction
            case .function(.right):
                .rightFunction
            default:
                .properNumber
            }
        }
    }

    // TODO: Finish the rest of the state transfer functions
}

extension Button {
    var isOther: Bool {
        Other(rawValue: self.rawValue) != nil
    }
}

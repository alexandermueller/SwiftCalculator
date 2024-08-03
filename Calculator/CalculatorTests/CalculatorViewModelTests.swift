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
    struct TestCase {
        let setupPresses: [Button]?

        init(setupPresses: [Button]? = nil) {
            self.setupPresses = setupPresses
        }
    }

    func evaluateTransferFunction(
        startingState: CalculatorViewModel.ExpressionState,
        testCases: [TestCase] = [TestCase()],
        expectedExpressionStateFor: (CalculatorViewModel, ExpressionList) -> CalculatorViewModel.ExpressionState
    ) {
        let viewModel = CalculatorViewModel()

        for testCase in testCases {
            for button in Button.allCases {
                if button.isOther {
                    continue
                }

                // Reset to .zero
                viewModel.goToZero()
                XCTAssertEqual(viewModel.currentExpressionState, .zero)

                // Setup test case
                if let setupPresses = testCase.setupPresses {
                    viewModel.simulate(buttonPresses: setupPresses)
                }
                XCTAssertEqual(viewModel.currentExpressionState, startingState)

                // Press button and compare results to expectations
                let previousExpressionElements = viewModel.expressionElements
                viewModel.buttonPressed = button
                XCTAssertEqual(viewModel.currentExpressionState, expectedExpressionStateFor(viewModel, previousExpressionElements),
                """

                \tResult\t\t->\t\(viewModel.currentExpressionState)
                \tExpected\t->\t\(expectedExpressionStateFor(viewModel, previousExpressionElements))
                \tButton\t\t->\t"\(button.rawValue)"
                \tBefore\t\t->\t\(previousExpressionElements)
                \tAfter\t\t->\t\(viewModel.expressionElements)

                """)
            }
        }
    }

    func test_goToZero_transferFunction() {
        evaluateTransferFunction(startingState: .zero) { viewModel, _ in
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
        evaluateTransferFunction(
            startingState: .properNumber,
            testCases: [
                .init(setupPresses: [
                    .parenthesis(.open),
                    .digit(.one)
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .digit(.one),
                    .modifier(.decimal),
                    .digit(.two)
                ])
            ]
        ) { viewModel, previousExpressionElements in
            return switch viewModel.modifiedButtonPressed {
            case .digit:
                .properNumber
            case .modifier:
                if let lastElement = previousExpressionElements.last, lastElement.isInteger() {
                    .modifiedNumber
                } else {
                    .properNumber
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

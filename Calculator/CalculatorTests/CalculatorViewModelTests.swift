//
//  CalculatorViewModelTests.swift
//  Swift CalculatorTests
//
//  Created by Alexander Mueller on 01.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import Swift_Calculator

typealias ExpressionState = CalculatorViewModel.ExpressionState

class CalculatorViewModelTests: UnitTestSuite {
    struct TestCase {
        let setupPresses: [Button]?

        init(setupPresses: [Button]? = nil) {
            self.setupPresses = setupPresses
        }
    }

    struct ViewModelSnapshot {
        let expressionState: ExpressionState
        let expressionElements: ExpressionList
        let parenthesisCount: Int

        init(expressionState: ExpressionState = .zero, expressionElements: ExpressionList = .defaultList, parenthesisCount: Int = 0) {
            self.expressionState = expressionState
            self.expressionElements = expressionElements
            self.parenthesisCount = parenthesisCount
        }
    }

    func evaluateTransferFunction(
        startingState: ExpressionState,
        testCases: [TestCase] = [TestCase()],
        expectedExpressionStateFor: (ViewModelSnapshot, Button, CalculatorViewModel) -> ExpressionState
    ) {
        let viewModel = CalculatorViewModel()

        for testCase in testCases {
            for button in Button.allCases {
                if button.isOtherType {
                    continue
                }

                // Reset to .zero
                viewModel.goToZero()
                XCTAssertEqual(viewModel.currentExpressionState, .zero)

                // Setup test case
                if let setupPresses = testCase.setupPresses {
                    viewModel.simulate(buttonPresses: setupPresses, wasZeroed: true)
                }
                
                XCTAssertEqual(viewModel.currentExpressionState, startingState)

                // Press button and compare results to expectations
                let snapshot = viewModel.snapshot
                viewModel.buttonPressed = button
                let expected = expectedExpressionStateFor(snapshot, button, viewModel)
                let errorMessage = """

                \tResult\t\t->\t\(viewModel.currentExpressionState)
                \tExpected\t->\t\(expected)
                \tButton\t\t->\t"\(button.rawValue)"
                \tBefore\t\t->\t\(snapshot.expressionElements)
                \tAfter\t\t->\t\(viewModel.expressionElements)

                """
                
                XCTAssertEqual(viewModel.currentExpressionState, expected, errorMessage)
            }
        }
    }

    func test_goToZero_transferFunction() {
        evaluateTransferFunction(startingState: .zero) { _, _, viewModel in
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
                    .digit(.one)
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .digit(.one),
                    .modifier(.decimal),
                    .digit(.two)
                ])
            ]
        ) { snapshot, _, viewModel in
            return switch viewModel.modifiedButtonPressed {
            case .digit:
                .properNumber
            case .modifier:
                if let lastElement = snapshot.expressionElements.last, lastElement.isInteger() {
                    .modifiedNumber
                } else {
                    .properNumber
                }
            case .parenthesis(.close):
                if snapshot.parenthesisCount > 0 {
                    .closeParenthesis
                } else {
                    .properNumber
                }
            case .function(.middle):
                .middleFunction
            case .function(.right):
                .rightFunction
            default:
                .properNumber
            }
        }
    }

    func test_goToModifiedNumber_transferFunction() {
        evaluateTransferFunction(
            startingState: .modifiedNumber,
            testCases: [
                .init(setupPresses: [
                    .modifier(.decimal)
                ]),
                .init(setupPresses: [
                    .digit(.zero),
                    .modifier(.decimal)
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .digit(.one),
                    .digit(.zero),
                    .modifier(.decimal)
                ])
            ]
        ) { _, _, viewModel in
            switch viewModel.modifiedButtonPressed {
            case .digit:
                .properNumber
            default:
                .modifiedNumber
            }
        }
    }

    func test_goToVariable_transferFunction() {
        evaluateTransferFunction(
            startingState: .variable,
            testCases: [
                .init(setupPresses: [
                    .variable(.answer)
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .variable(.answer)
                ])
            ]
        ) { snapshot, buttonPressed, viewModel in
            if case let .convenience(convenience) = buttonPressed {
                switch convenience {
                case .fraction:
                    .variable
                case .square:
                    .properNumber
                }
            } else {
                switch viewModel.modifiedButtonPressed {
                case .function(.middle):
                    .middleFunction
                case .function(.right):
                    .rightFunction
                case .parenthesis(.close):
                    if snapshot.parenthesisCount > 0 {
                        .closeParenthesis
                    } else {
                        .variable
                    }
                default:
                    .variable
                }
            }
        }
    }

    func test_goToOpenParenthesis_transferFunction() {
        evaluateTransferFunction(
            startingState: .openParenthesis,
            testCases: [
                .init(setupPresses: [
                    .parenthesis(.open)
                ]),
                .init(setupPresses: [
                    .function(.left(.sqrt)),
                    .parenthesis(.open)
                ]),
                .init(setupPresses: [
                    .convenience(.fraction),
                    .parenthesis(.open)
                ])
            ]
        ) { _, buttonPressed, viewModel in
            if case let .convenience(convenience) = buttonPressed {
                switch convenience {
                case .fraction:
                    .middleFunction
                case .square:
                    .openParenthesis
                }
            } else {
                switch viewModel.modifiedButtonPressed {
                case .digit:
                    .properNumber
                case .modifier(.decimal):
                    .modifiedNumber
                case .parenthesis(.open):
                    .openParenthesis
                case .function(.left):
                    .leftFunction
                case .variable:
                    .variable
                default:
                    .openParenthesis
                }
            }
        }
    }

    func test_goToCloseParenthesis_transferFunction() {
        evaluateTransferFunction(
            startingState: .closeParenthesis,
            testCases: [
                .init(setupPresses: [
                    .parenthesis(.open),
                    .digit(.one),
                    .parenthesis(.close)
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .parenthesis(.open),
                    .digit(.one),
                    .parenthesis(.close)
                ])
            ]
        ) { _, buttonPressed, viewModel in
            if case let .convenience(convenience) = buttonPressed {
                switch convenience {
                case .fraction:
                    .closeParenthesis
                case .square:
                    .properNumber
                }
            } else {
                switch viewModel.modifiedButtonPressed {
                case .parenthesis(.close):
                    .closeParenthesis
                case .function(.middle):
                    .middleFunction
                case .function(.right):
                    .rightFunction
                default:
                    .closeParenthesis
                }
            }
        }
    }

    func test_goToLeftFunction_transferFunction() {
        evaluateTransferFunction(
            startingState: .leftFunction,
            testCases: [
                .init(setupPresses: [
                    .function(.left(.sqrt))
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .function(.left(.negate))
                ])
            ]
        ) { snapshot, buttonPressed, viewModel in
            if case let .convenience(convenience) = buttonPressed {
                switch convenience {
                case .fraction:
                    .middleFunction
                case .square:
                    .leftFunction
                }
            } else {
                switch viewModel.modifiedButtonPressed {
                case .digit:
                    .properNumber
                case .modifier(.decimal):
                    .modifiedNumber
                case .parenthesis(.open):
                    .openParenthesis
                case .function(.left):
                    .leftFunction
                case .variable:
                    .variable
                default:
                    .leftFunction
                }
            }
        }
    }

    func test_goToMiddleFunction_transferFunction() {
        evaluateTransferFunction(
            startingState: .middleFunction,
            testCases: [
                .init(setupPresses: [
                    .digit(.one),
                    .function(.middle(.add))
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .digit(.one),
                    .function(.middle(.exponent))
                ])
            ]
        ) { _, buttonPressed, viewModel in
            if case let .convenience(convenience) = buttonPressed {
                switch convenience {
                case .fraction, .square:
                    .middleFunction
                }
            } else {
                switch viewModel.modifiedButtonPressed {
                case .digit:
                    .properNumber
                case .modifier(.decimal):
                    .modifiedNumber
                case .parenthesis(.open):
                    .openParenthesis
                case .function(.left):
                    .leftFunction
                case .variable:
                    .variable
                default:
                    .middleFunction
                }
            }
        }
    }

    func test_goToRightFunction_transferFunction() {
        evaluateTransferFunction(
            startingState: .rightFunction,
            testCases: [
                .init(setupPresses: [
                    .digit(.one),
                    .function(.right(.factorial))
                ]),
                .init(setupPresses: [
                    .parenthesis(.open),
                    .digit(.one),
                    .function(.right(.factorial))
                ])
            ]
        ) { snapshot, buttonPressed, viewModel in
            if case let .convenience(convenience) = buttonPressed {
                switch convenience {
                case .fraction:
                    .rightFunction
                case .square:
                    .properNumber
                }
            } else {
                switch viewModel.modifiedButtonPressed {
                case .parenthesis(.close):
                    if snapshot.parenthesisCount > 0 {
                        .closeParenthesis
                    } else {
                        .rightFunction
                    }
                case .function(.middle):
                    .middleFunction
                case .function(.right):
                    .rightFunction
                default:
                    .rightFunction
                }
            }
        }
    }

    func test_goToDelete_transferFunction() {
        var simulatedPresses: [Button] = [
            .function(.left(.negate)),
            .parenthesis(.open),
            .digit(.eight),
            .modifier(.decimal),
            .digit(.eight),
            .digit(.four),
            .digit(.three),
            .function(.middle(.add)),
            .digit(.two),
            .parenthesis(.close),
            .function(.middle(.multiply)),
            .digit(.two),
            .function(.right(.factorial))
        ]

        let viewModel = CalculatorViewModel()

        while !simulatedPresses.isEmpty {
            let snapshot = viewModel.snapshot
            let lastExpressionText = viewModel.expressionText

            for button in Button.allCases {
                if button.isOtherType {
                    continue
                }

                viewModel.simulate(buttonPress: button)

                if lastExpressionText != viewModel.expressionText {
                    let newExpressionElements = viewModel.expressionElements
                    viewModel.simulate(buttonPress: .other(.delete))

                    var expectedState: ExpressionState = snapshot.expressionState

                    if let previousState = button.modifiedPreviousStates(previousState: snapshot.expressionState)?.last {
                        expectedState = previousState
                    }

                    let errorMessage = """

                    \tResult\t\t->\t\(viewModel.currentExpressionState)
                    \tExpected\t\t->\t\(expectedState)
                    \tButton\t\t->\t"\(button.rawValue)"
                    \tBefore\t\t->\t\(snapshot.expressionElements)
                    \tButton\t\t->\t\(newExpressionElements)
                    \tDelete\t\t->\t\(viewModel.expressionElements)

                    """

                    XCTAssertEqual(expectedState, viewModel.currentExpressionState, errorMessage)
                }
            }

            let simulatedPress = simulatedPresses.removeFirst()
            viewModel.simulate(buttonPress: simulatedPress)
        }
    }
}

extension Button {
    var isOtherType: Bool {
        Other(rawValue: self.rawValue) != nil
    }
}

extension CalculatorViewModel {
    var snapshot: CalculatorViewModelTests.ViewModelSnapshot {
        .init(
            expressionState: currentExpressionState,
            expressionElements: expressionElements,
            parenthesisCount: parenBalance
        )
    }
}

extension Button {
    func modifiedPreviousStates(previousState: ExpressionState? = nil) -> [ExpressionState]? {
        switch self {
        case .digit, .parenthesis, .function, .variable, .other:
            nil
        case .modifier:
            switch previousState {
            case .none, .zero, .openParenthesis, .leftFunction, .middleFunction:
                [.properNumber]
            case .properNumber, .modifiedNumber, .variable, .closeParenthesis, .rightFunction:
                nil
            }
        case .convenience(let convenience):
            switch convenience {
            case .square:
                [.middleFunction]
            case .fraction:
                [.properNumber]
            }
        }
    }
}

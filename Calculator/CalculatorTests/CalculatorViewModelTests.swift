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
    func testStateMachine() {
        typealias UnitTest = TemplateTest<[Button], Swift_Calculator.CalculatorViewModel.ExpressionState>

        let testCaseSuite: [String : (SuccessCondition, [UnitTest])] = [
            "Empty" : (.equivalent, [
                UnitTest([], .zero),
                UnitTest([.digit(.five), .other(.delete)], .zero),
                UnitTest([.modifier(.decimal), .digit(.zero), .function(.right(.factorial)), .other(.clear)], .zero)
            ]),
        ]

        evaluateTestCaseSuite(testCaseSuite) { testCase in
            let viewModel = CalculatorViewModel()
            viewModel.simulate(pressedButtonCombo: testCase)

            return viewModel.currentExpressionState
        }
    }
}

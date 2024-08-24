//
//  ButtonTests.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 2021-04-27.
//  Copyright © 2021 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import Swift_Calculator

class ButtonTests: UnitTestSuite {
    func test_ButtonTests_buttonDisplayValue() {
        testCasesEvaluateNonNilOrEmpty(Button.allCases) { testCase in
            testCase.buttonDisplayValue
        }
    }
    
    func test_ButtonTests_rawValue() {
        testCasesEvaluateNonNilOrEmpty(Button.allCases) { testCase in
            testCase.rawValue
        }
    }
    
    func test_ButtonTests_fromRawValue() {
        evaluateTestCases(Button.allCases.map { TemplateTest<String, String>($0.rawValue, $0.rawValue) }) { testCase in
            Button.from(rawValue: testCase)?.rawValue ?? ""
        }
    }
}

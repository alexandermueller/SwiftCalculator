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
    func testButtonDisplayValue() {
        testCasesEvaluateNonNilOrEmpty(Button.allCases, using: { $0.buttonDisplayValue })
    }
    
    func testRawValue() {
        testCasesEvaluateNonNilOrEmpty(Button.allCases, using: { $0.rawValue })
    }
    
    func testFromRawValue() {
        evaluateTestCases(Button.allCases.map({ TemplateTest<String, String>($0.rawValue, $0.rawValue) }), using: { Button.from(rawValue: $0)?.rawValue ?? "" })
    }
}

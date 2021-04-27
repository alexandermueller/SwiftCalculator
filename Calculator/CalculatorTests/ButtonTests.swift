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
    func testFromRawValue() {
        typealias UnitTest = TemplateTest<String, String>
        
        
        
        let testCaseSuite: [String : (SuccessCondition, [UnitTest])] = [
            "Digit"       : (.equivalent, Digit.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Modifier"    : (.equivalent, Modifier.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Parentheses" : (.equivalent, Parenthesis.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Left"        : (.equivalent, Left.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Middle"      : (.equivalent, Middle.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Right"       : (.equivalent, Right.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Variable"    : (.equivalent, Variable.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Convenience" : (.equivalent, Convenience.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
            "Other"       : (.equivalent, Other.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
        ]
        
        evaluateTestCaseSuite(testCaseSuite, using: { Button.from(rawValue: $0)?.rawValue ?? "" })
    }
    
    func testButtonDisplayValue() {
        typealias UnitTest = TemplateTest<String, String>
        
        
//        let testCaseSuite: [String : (SuccessCondition, [UnitTest])] = [
//            "Digit"       : (.equivalent, Digit.allCases.map({ UnitTest($0.buttonDisplayValue, $0.rawValue) })),
//            "Modifier"    : (.equivalent, Modifier.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
//            "Parentheses" : (.equivalent, Parenthesis.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
//            "Variable"    : (.equivalent, Variable.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
//            "Convenience" : (.equivalent, Convenience.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
//            "Other"       : (.equivalent, Other.allCases.map({ UnitTest($0.rawValue, $0.rawValue) })),
//        ]
//        
//        evaluateTestCaseSuite(testCaseSuite, using: { Button.from(rawValue: $0)?.rawValue() ?? "" })
    }
}

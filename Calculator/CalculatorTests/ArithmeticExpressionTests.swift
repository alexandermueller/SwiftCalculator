//
//  ArithmeticExpressionTests.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2019-09-30.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import Calculator

typealias TemplateTest<I, O> = (input: I, output: O)

class ArithmeticExpressionTests: XCTestCase {
    func testArithmeticExpressionEvaluate() {
        typealias UnitTest = TemplateTest<ArithmeticExpression, Double>
        
        let testCases: [UnitTest] = [
            UnitTest(.error, .nan),
            UnitTest(.number(.nan), .nan),
            UnitTest(.number(2), 2),
            UnitTest(.number(-3), -3),
            UnitTest(.number(.infinity), .infinity),
            UnitTest(.negation(.error), .nan),
            UnitTest(.negation(.number(3)), -3),
            UnitTest(.addition(.number(1), .error), .nan),
            UnitTest(.addition(.number(1), .number(2)), 3),
            UnitTest(.addition(.number(2), .negation(.number(2))), 0),
            UnitTest(.subtraction(.error, .number(3)), .nan),
            UnitTest(.subtraction(.number(3), .error), .nan),
            UnitTest(.subtraction(.number(2), .number(3)), -1),
            UnitTest(.subtraction(.number(2), .negation(.number(3))), 5),
            UnitTest(.multiplication(.number(1), .error), .nan),
            UnitTest(.multiplication(.error, .number(1)), .nan),
            UnitTest(.multiplication(.number(1), .number(2)), 2),
            UnitTest(.multiplication(.number(2), .negation(.number(3))), -6),
            UnitTest(.multiplication(.addition(.number(2), .number(4)), .subtraction(.number(2), .number(5))), -18),
            UnitTest(.division(.number(1), .error), .nan),
            UnitTest(.division(.error, .number(1)), .nan),
            UnitTest(.division(.number(1), .number(0)), .infinity),
            UnitTest(.division(.number(1), .number(.infinity)), 0),
            UnitTest(.division(.number(.infinity), .number(.infinity)), -.nan),
            UnitTest(.division(.number(0), .number(.infinity)), 0),
            UnitTest(.division(.number(1), .number(2)), 0.5),
            UnitTest(.exponentiation(.error, .number(2)), .nan),
            UnitTest(.exponentiation(.number(1), .error), .nan),
            UnitTest(.exponentiation(.number(4), .number(0.5)), 2),
            UnitTest(.exponentiation(.number(3), .number(0)), 1),
            UnitTest(.exponentiation(.number(.infinity), .number(0)), 1),
            UnitTest(.exponentiation(.number(0), .number(.infinity)), 0)
            // TODO: Make root unit tests
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let output = testCase.input.evaluate()
            XCTAssert(output == testCase.output || output.isNaN && testCase.output.isNaN, String(format: "Test Case \(index + 1) Failed.\nExpected: \(testCase.output),\n\tSaw: \(output)"))
        }
    }
    
    func testMapParentheses() {
        typealias UnitTest = TemplateTest<[String], ParenthesesMappingResult>
        
        let testCases: [UnitTest] = [
            UnitTest([], ParenthesesMappingResult([], [:])),
            UnitTest([""], ParenthesesMappingResult([""], [:])),
            UnitTest(["(", "5234", "-"], ParenthesesMappingResult([], [:])), // The input contained imbalanced parentheses, so it returned an empty processedExpresisonList
            UnitTest(["(", "234", ")"], ParenthesesMappingResult(["p0,2,0"], ["p0,2,0" : ["234"]])),
            UnitTest(["(", "12", "-", "23", "^", "(", "23", "-", "32", ")", ")"], ParenthesesMappingResult(["p0,10,0"], ["p0,10,0" : ["12", "-", "23", "^", "(", "23", "-", "32", ")"]])),
            UnitTest(["(", "234", ")", "+", "(", "234", ")", "-", "(", "234", ")", "^", "(", "234", ")"], ParenthesesMappingResult(["p0,2,0", "+", "p4,6,1", "-", "p8,10,2", "^", "p12,14,3"], ["p0,2,0" : ["234"], "p4,6,1" : ["234"], "p8,10,2" : ["234"], "p12,14,3" : ["234"]]))
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let output = mapParentheses(testCase.input)
            XCTAssert(output == testCase.output, String(format: "Test Case \(index + 1) Failed.\nExpected: \(testCase.output),\n\tSaw: \(output)"))
        }
    }
    
    func testParseExpression() {
        typealias UnitTest = TemplateTest<[String], ArithmeticExpression>
        
        let testCases: [UnitTest] = [
            UnitTest([], .error),
            UnitTest(["1"], .number(1)),
            UnitTest(["1", "+", "2"], .addition(.number(1), .number(2))),
            UnitTest(["(", "1", ")"], .number(1)),
            UnitTest(["(", "1", ")", "+", "(", "1", ")"], .addition(.number(1), .number(1))),
            UnitTest(["(", "1", "-", "(", "2", "+", "1", ")", ")"], .subtraction(.number(1), .addition(.number(2), .number(1)))),
            UnitTest(["(", "3", "÷", "20", ")", "^", "2"], .exponentiation(.division(.number(3), .number(20)), .number(2))),
            UnitTest(["1", "÷", "3", "^", "(", "5", "-", "7", ")"], .division(.number(1), .exponentiation(.number(3), .subtraction(.number(5), .number(7))))),
            UnitTest(["-3", "^", "2", "^", "0.5"], .exponentiation(.exponentiation(.number(-3), .number(2)), .number(0.5))),
            UnitTest(["(", "-3", "^", "2", ")", "^", "0.5"], .exponentiation(.exponentiation(.number(-3), .number(2)), .number(0.5))),
            UnitTest(["1", "+", "2", "^", "3", "-", "5", "^", "2", "÷", "3", "÷", "3"], .addition(.number(1.0), .subtraction(.exponentiation(.number(2.0), .number(3.0)), .division(.division(.exponentiation(.number(5.0), .number(2.0)), .number(3.0)), .number(3.0))))),
            UnitTest(["1", "√", "2"], .root(.number(1), .number(2))),
            // Add more unit tests
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let output = parseExpression(testCase.input)
            XCTAssert(output == testCase.output, String(format: "Test Case \(index + 1) Failed.\nExpected: \(testCase.output)\n\tSaw: \(output)"))
        }
    }
}

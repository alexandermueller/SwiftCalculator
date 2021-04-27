//
//  UnitTestSuite.swift
//  Swift CalculatorTests
//
//  Created by Alexander Mueller on 2021-04-27.
//  Copyright © 2021 Alexander Mueller. All rights reserved.
//

import XCTest
import Foundation

let kErrorThreshold: MaxPrecisionNumber = 1 * powl(10, -18)

enum SuccessCondition {
    case equivalent
    case approximate(within: MaxPrecisionNumber)
}

typealias TemplateTest<I, O: UnitTestOutput> = (input: I, output: O)

class UnitTestSuite : XCTestCase {
    func testCasesEvaluateNonNilOrEmpty<I, O: UnitTestOutput>(_ testCases: [I], using outputClosure: (I) -> O) {
        for input in testCases {
            let output = outputClosure(input)
            XCTAssert(!output.isNaN() && !output.isEmpty(), "Test Case For Input \"\(input)\" Failed.\nSaw \"\(output)\".")
        }
    }
    
    func evaluateTestCases<I, O: UnitTestOutput>(_ testCases: [TemplateTest<I, O>], using outputClosure: (I) -> O) {
        for testCase in testCases {
            let output = outputClosure(testCase.input)
            XCTAssert(output == testCase.output || output.isNaN() && testCase.output.isNaN(), "Test Case For Input \(testCase) Failed.\nExpected: \(testCase.output),\n\t  Saw: \(output) ")
        }
    }
    
    func evaluateTestCaseSuite<I, O: UnitTestOutput>(_ testCaseSuite: [String : (SuccessCondition, [TemplateTest<I, O>])], using outputClosure: (I) -> O) {
        for (section, (condition, testCases)) in testCaseSuite {
            for (index, testCase) in testCases.enumerated() {
                let output = outputClosure(testCase.input)
                
                switch condition {
                case .approximate(within: let threshold):
                    let outputError = output |-| testCase.output
                    XCTAssert(outputError.isNaN() && output == testCase.output || outputError.isPositive() && outputError <= threshold, "Test Case \(index + 1)/\(testCases.count) in '\(section)' Failed.\nExpected: \(testCase.output),\n\t  Saw: \(outputError) for \(output)")
                case .equivalent:
                    XCTAssert(output == testCase.output || output.isNaN() && testCase.output.isNaN(), "Test Case \(index + 1)/\(testCases.count) in '\(section)' Failed.\nExpected: \(testCase.output),\n\t  Saw: \(output)")
                }
            }
        }
    }
}

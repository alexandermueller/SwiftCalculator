//
//  UnitTestSuite.swift
//  Swift CalculatorTests
//
//  Created by Alexander Mueller on 2021-04-27.
//  Copyright © 2021 Alexander Mueller. All rights reserved.
//

import XCTest
import Foundation

enum SuccessCondition {
    case equivalent
    case approximate
}

typealias TemplateTest<I, O: UnitTestOutput> = (input: I, output: O)

class UnitTestSuite: XCTestCase {
    func testCasesEvaluateNonNilOrEmpty<I, O: UnitTestOutput>(_ testCases: [I], using outputClosure: (I) -> O) {
        for input in testCases {
            let output = outputClosure(input)
            XCTAssert(
                !output.isNaN() && !output.isEmpty(), 
                """
                
                Test Case For Input \"\(input)\" Failed.
                Saw \"\(output)\".
                
                """
            )
        }
    }
    
    func testCasesEvaluateError<I, O: UnitTestOutput>(_ testCaseSuite: [String : (SuccessCondition, [TemplateTest<I, O>])], using outputClosure: (I) throws -> Void) {
        for (section, (condition, testCases)) in testCaseSuite {
            for (index, testCase) in testCases.enumerated() {
                do {
                    _ = try outputClosure(testCase.input)
                } catch let error {
                    guard let error = error as? O else {
                        XCTFail(
                            """

                            Test Case \(index + 1)/\(testCases.count) in '\(section)' Failed.
                            Expected: \(testCase.output),
                                 Saw: \(error)

                            """
                        )
                        continue
                    }

                    let assertion = {
                        switch condition {
                        case .equivalent:
                            error == testCase.output
                        case .approximate:
                            error ≈≈ testCase.output
                        }
                    }()

                    XCTAssert(
                        assertion,
                        """

                        Test Case \(index + 1)/\(testCases.count) in '\(section)' Failed.
                        Expected: \(testCase.output),
                             Saw: \(error)

                        """
                    )
                }
            }
        }
    }

    func evaluateTestCases<I, O: UnitTestOutput>(_ testCases: [TemplateTest<I, O>], using outputClosure: (I) -> O) {
        for testCase in testCases {
            let output = outputClosure(testCase.input)
            XCTAssert(
                output == testCase.output || output.isNaN() && testCase.output.isNaN(), 
                """
                
                Test Case For Input \(testCase) Failed.
                Expected: \(testCase.output),
                     Saw: \(output)
                
                """
            )
        }
    }
    
    func evaluateTestCaseSuite<I, O: UnitTestOutput>(_ testCaseSuite: [String : (SuccessCondition, [TemplateTest<I, O>])], using outputClosure: (I) -> O) {
        for (section, (condition, testCases)) in testCaseSuite {
            for (index, testCase) in testCases.enumerated() {
                let output = outputClosure(testCase.input)
                let assertion = {
                    switch condition {
                    case .equivalent:
                        output == testCase.output
                    case .approximate:
                        output ≈≈ testCase.output
                    }
                }()

                XCTAssert(
                    assertion,
                    """

                    Test Case \(index + 1)/\(testCases.count) in '\(section)' Failed.
                    Expected: \(testCase.output),
                         Saw: \(output)

                    """
                )
            }
        }
    }
}

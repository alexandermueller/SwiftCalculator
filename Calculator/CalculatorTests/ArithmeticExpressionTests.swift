//
//  ArithmeticExpressionTests.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2019-09-30.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import Calculator

let kErrorThreshold: Double = 0.008

enum SuccessCondition {
    case equivalent
    case approximate(within: Double) // To a certain percent of the expected value
}

typealias TemplateTest<I, O: UnitTestOutput> = (input: I, output: O)

class ArithmeticExpressionTests: XCTestCase {
    func testParseExpression() {
        typealias UnitTest = TemplateTest<[String], ArithmeticExpression>
        
        let testCaseSuite: [String : (SuccessCondition, [UnitTest])] = [
            "Empty" : (.equivalent, [
                UnitTest([], .empty)
            ]),
            
            "Number, Double" : (.equivalent, [
                UnitTest(["0."], .error),
                UnitTest(["1"], .number(1)),
                UnitTest(["0.000001"], .number(0.000001))
            ]),
            
            "Addition" : (.equivalent, [
                UnitTest(["0", "+"], .error),
                UnitTest(["0", "+", "0."], .error),
                UnitTest(["1", "+", "2"], .addition(.number(1), .number(2))),
                UnitTest(["1", "+", "2", "+", "1", "+", "2"], .addition(.addition(.addition(.number(1), .number(2)), .number(1)), .number(2)))
            ]),
            
            "Subtraction" : (.equivalent, [
                UnitTest(["0", "-"], .error),
                UnitTest(["0", "-", "0."], .error),
                UnitTest(["1", "–", "1"], .subtraction(.number(1), .number(1))),
                UnitTest(["1", "+", "2", "+", "1", "+", "2"], .addition(.addition(.addition(.number(1), .number(2)), .number(1)), .number(2)))
            ]),
            
            "Addition + Subtraction" : (.equivalent, [
                UnitTest(["1", "+", "1", "–", "1"], .subtraction(.addition(.number(1), .number(1)), .number(1))),
                UnitTest(["1", "–", "1", "+", "1"], .addition(.subtraction(.number(1), .number(1)), .number(1)))
            ]),
            
            "Modulo" : (.equivalent, [
                UnitTest(["0", "%"], .error),
                UnitTest(["0", "%", "0."], .error),
                UnitTest(["1", "+", "1", "%", "1"], .addition(.number(1), .modulo(.number(1), .number(1)))),
                UnitTest(["1", "%", "1", "–", "1"], .subtraction(.modulo(.number(1), .number(1)), .number(1))),
                UnitTest(["3", "%", "4", "%", "5"], .modulo(.modulo(.number(3), .number(4)), .number(5)))
            ]),
            
            "Negation" : (.equivalent, [
                UnitTest(["-"], .error),
                UnitTest(["-", "1"], .negation(.number(1))),
                UnitTest(["-", "-", "1"], .negation(.negation(.number(1)))),
                UnitTest(["-", "1", "–", "1"], .subtraction(.negation(.number(1)), .number(1))),
            ]),
            
            //            UnitTest(["(", "1", ")"], .number(1)),
            //            UnitTest(["(", "1", ")", "+", "(", "1", ")"], .addition(.number(1), .number(1))),
            //            UnitTest(["(", "1", "–", "(", "2", "+", "1", ")", ")"], .subtraction(.number(1), .addition(.number(2), .number(1)))),
            //            UnitTest(["(", "3", "÷", "20", ")", "^", "2"], .exponentiation(.division(.number(3), .number(20)), .number(2))),
            //            UnitTest(["1", "÷", "3", "^", "(", "5", "–", "7", ")"], .division(.number(1), .exponentiation(.number(3), .subtraction(.number(5), .number(7))))),
            //            UnitTest(["-", "3", "^", "2", "^", "0.5"], .negation(.exponentiation(.number(3), .exponentiation(.number(2), .number(0.5))))),
            //            UnitTest(["(", "-3", "^", "2", ")", "^", "0.5"], .exponentiation(.exponentiation(.number(-3), .number(2)), .number(0.5))),
        //            UnitTest(["1", "+", "2", "^", "3", "–", "5", "^", "2", "÷", "3", "÷", "3"], .subtraction(.addition(.number(1.0), .exponentiation(.number(2.0), .number(3.0))), .division(.division(.exponentiation(.number(5.0), .number(2.0)), .number(3.0)), .number(3.0)))),
        //            UnitTest(["1", "*√", "2"], .root(.number(1), .number(2))),
        //            UnitTest(["2", "^", "2", "^", "0.5"], .exponentiation(.number(2), .exponentiation(.number(2), .number(0.5)))),
        //            UnitTest(["2", "^", "-", "2", "^", "0.5"], .exponentiation(.number(2), .negation(.exponentiation(.number(2), .number(0.5))))),
        //            UnitTest(["2", "*√", "2", "^", "2"], .root(.number(2), .exponentiation(.number(2), .number(2)))),
            // TODO: Add more unit tests
        ]
        
        evaluateTestCaseSuite(testCaseSuite, using: { input in
            return Generator().startGenerator(with: input).value
        })
    }
    
    func testArithmeticExpressionEvaluate() {
        typealias UnitTest = TemplateTest<ArithmeticExpression, Float80>
        
        let testCaseSuite: [String : (SuccessCondition, [UnitTest])] = [
            "Empty, Error, NaN" : (.equivalent, [
                UnitTest(.empty, .nan),
                UnitTest(.error, .nan),
                UnitTest(.number(.nan), .nan)
            ]),

            "Number, Double, Infinity" : (.equivalent, [
                UnitTest(.number(2), 2),
                UnitTest(.number(-3), -3),
                UnitTest(.number(-0.1), -0.1),
                UnitTest(.number(.infinity), .infinity),
                UnitTest(.number(-.infinity), -.infinity)
            ]),

            "Negation" : (.equivalent, [
                UnitTest(.negation(.number(.nan)), .nan),
                UnitTest(.negation(.number(.infinity)), -.infinity),
                UnitTest(.negation(.number(-.infinity)), .infinity),
                UnitTest(.negation(.number(0)), 0),
                UnitTest(.negation(.number(1)), -1),
                UnitTest(.negation(.negation(.number(1))), 1)
            ]),

            "Error: Addition, Subtraction" : (.equivalent, [
                UnitTest(.addition(.number(.nan), .number(1)), .nan),
                UnitTest(.addition(.number(1), .number(.nan)), .nan),
                UnitTest(.addition(.number(.infinity), .number(-.infinity)), -.nan),
                UnitTest(.subtraction(.number(.infinity), .number(.infinity)), -.nan),
                UnitTest(.subtraction(.number(.infinity), .number(.infinity)), -.nan),
                UnitTest(.subtraction(.number(-.infinity), .number(-.infinity)), -.nan),
                UnitTest(.subtraction(.number(.nan), .number(3)), .nan),
                UnitTest(.subtraction(.number(3), .number(.nan)), .nan)
            ]),

            "Addition, Subtraction": (.equivalent, [
                UnitTest(.addition(.number(1), .number(2)), 3),
                UnitTest(.subtraction(.number(2), .number(3)), -1),
                UnitTest(.addition(.subtraction(.number(1), .number(4)), .number(3)), 0),
                UnitTest(.addition(.number(.infinity), .number(.infinity)), .infinity),
                UnitTest(.addition(.number(-.infinity), .number(-.infinity)), -.infinity),
                UnitTest(.addition(.negation(.number(1)), .number(1)), 0),
                UnitTest(.addition(.negation(.number(1)), .negation(.number(1))), -2),
                UnitTest(.subtraction(.negation(.number(1)), .number(1)), -2),
                UnitTest(.subtraction(.number(1), .negation(.number(1))), 2)
            ]),

            "Error: Modulo" : (.equivalent, [
                UnitTest(.modulo(.number(.nan), .number(1)), .nan),
                UnitTest(.modulo(.number(1), .number(.nan)), .nan),
                UnitTest(.modulo(.number(.infinity), .number(1)), .nan),
                UnitTest(.modulo(.number(-.infinity), .number(1)), -.nan),
                UnitTest(.modulo(.number(.infinity), .number(.infinity)), .nan),
                UnitTest(.modulo(.number(-.infinity), .number(-.infinity)), .nan),
                UnitTest(.modulo(.number(.infinity), .number(-.infinity)), -.nan),
                UnitTest(.modulo(.number(-.infinity), .number(.infinity)), -.nan),
                UnitTest(.modulo(.number(1), .number(0)), .nan)
            ]),

            "Modulo" : (.equivalent, [
                UnitTest(.modulo(.number(1), .number(1)), 0),
                UnitTest(.modulo(.number(0), .number(1)), 0),
                UnitTest(.modulo(.number(2), .number(1)), 0),
                UnitTest(.modulo(.number(100), .number(3)), 1),
                UnitTest(.modulo(.number(-100), .number(-3)), -1),
                UnitTest(.modulo(.number(-100), .number(3)), 2),
                UnitTest(.modulo(.number(100), .number(-3)), -2),
                UnitTest(.modulo(.number(3), .number(100)), 3),
                UnitTest(.modulo(.number(-3), .number(100)), 97),
                UnitTest(.modulo(.number(3), .number(-100)), -97),
                UnitTest(.modulo(.number(1), .number(.infinity)), 1),
                UnitTest(.modulo(.number(-1), .number(.infinity)), .infinity),
                UnitTest(.modulo(.number(-1), .number(-.infinity)), -1),
                UnitTest(.modulo(.number(1), .number(-.infinity)), -.infinity)
            ]),

            "Error: Multiplication, Division" : (.equivalent, [
                UnitTest(.multiplication(.number(.nan), .number(.nan)), .nan),
                UnitTest(.multiplication(.number(.nan), .number(.infinity)), .nan),
                UnitTest(.multiplication(.number(.nan), .number(-.infinity)), .nan),
                UnitTest(.division(.number(.nan), .number(.nan)), .nan),
                UnitTest(.division(.number(0), .number(0)), .nan),
                UnitTest(.division(.number(.infinity), .number(.nan)), .nan),
                UnitTest(.division(.number(.nan), .number(.infinity)), .nan),
                UnitTest(.division(.number(-.infinity), .number(.nan)), .nan),
                UnitTest(.division(.number(.nan), .number(-.infinity)), .nan),
                UnitTest(.multiplication(.number(.infinity), .number(0)), -.nan),
                UnitTest(.multiplication(.number(-.infinity), .number(0)), -.nan)
            ]),

            "Multiplication" : (.equivalent, [
                UnitTest(.multiplication(.number(0), .number(0)), 0),
                UnitTest(.multiplication(.number(1), .number(0)), 0),
                UnitTest(.multiplication(.negation(.number(1)), .number(0)), 0),
                UnitTest(.multiplication(.number(1), .number(1)), 1),
                UnitTest(.multiplication(.number(1), .number(2)), 2),
                UnitTest(.multiplication(.number(2), .number(0.5)), 1),
                UnitTest(.multiplication(.negation(.number(1)), .number(2)), -2),
                UnitTest(.multiplication(.number(.infinity), .number(.infinity)), .infinity),
                UnitTest(.multiplication(.number(.infinity), .number(-.infinity)), -.infinity)
            ]),

            "Division" : (.equivalent, [
                UnitTest(.division(.number(0), .number(1)), 0),
                UnitTest(.division(.number(0), .negation(.number(1))), 0),
                UnitTest(.division(.number(1), .number(1)), 1),
                UnitTest(.division(.number(2), .number(1)), 2),
                UnitTest(.division(.number(1), .number(2)), 0.5),
                UnitTest(.division(.number(2), .number(2)), 1),
                UnitTest(.division(.negation(.number(1)), .number(2)), -0.5),
                UnitTest(.division(.number(2), .negation(.number(1))), -2),
                UnitTest(.division(.number(1), .number(0)), .infinity),
                UnitTest(.division(.number(-1), .number(0)), -.infinity),
                UnitTest(.division(.number(0), .number(.infinity)), 0),
                UnitTest(.division(.number(0), .number(-.infinity)), 0),
                UnitTest(.division(.number(.infinity), .number(0)), .infinity),
                UnitTest(.division(.number(-.infinity), .number(0)), -.infinity)
            ]),

            "Multiplication + Division" : (.equivalent, [
                UnitTest(.multiplication(.division(.number(1), .number(2)), .number(2)), 1),
                UnitTest(.multiplication(.number(2), .division(.number(1), .number(2))), 1),
                UnitTest(.division(.multiplication(.number(1), .number(2)), .number(2)), 1),
                UnitTest(.division(.number(2), .multiplication(.number(1), .number(2))), 1)
            ]),

            "Error: Square Root, Inverse, Square" : (.equivalent, [
                UnitTest(.squareRoot(.number(.nan)), .nan),
                UnitTest(.squareRoot(.number(-.nan)), .nan),
                UnitTest(.squareRoot(.negation(.number(1))), -.nan),
                UnitTest(.squareRoot(.number(-.infinity)), -.nan),
                UnitTest(.square(.number(.nan)), .nan),
                UnitTest(.square(.number(-.nan)), .nan),
                UnitTest(.inverse(.number(.nan)), .nan),
                UnitTest(.inverse(.number(-.nan)), .nan),
            ]),

            "Square Root" : (.equivalent, [
                UnitTest(.squareRoot(.number(0)), 0),
                UnitTest(.squareRoot(.number(1)), 1),
                UnitTest(.squareRoot(.number(9)), 3),
                UnitTest(.squareRoot(.number(.infinity)), .infinity),
                UnitTest(.squareRoot(.square(.number(9))), 9),
                UnitTest(.squareRoot(.square(.number(100))), 100),
                UnitTest(.squareRoot(.square(.number(10000000000))), 10000000000),
                UnitTest(.squareRoot(.square(.number(10000000000.0000000001))), 10000000000.0000000001),
                UnitTest(.squareRoot(.square(.number(.infinity))), .infinity)
            ]),

            "Square" : (.equivalent, [
                UnitTest(.square(.number(0)), 0),
                UnitTest(.square(.number(1)), 1),
                UnitTest(.square(.number(3)), 9),
                UnitTest(.square(.number(-.infinity)), .infinity),
                UnitTest(.square(.squareRoot(.number(9))), 9),
                UnitTest(.square(.squareRoot(.number(100))), 100),
                UnitTest(.square(.squareRoot(.number(10000000000))), 10000000000),
                UnitTest(.square(.squareRoot(.number(10000000000.0000000001))), 10000000000.0000000001),
                UnitTest(.square(.squareRoot(.number(.infinity))), .infinity)
            ]),

            "Inverse" : (.equivalent, [
                UnitTest(.inverse(.number(1)), 1),
                UnitTest(.inverse(.number(2)), 0.5),
                UnitTest(.square(.inverse(.number(2))), 0.25),
                UnitTest(.inverse(.square(.number(2))), 0.25),
                UnitTest(.squareRoot(.inverse(.number(4))), 0.5),
                UnitTest(.inverse(.squareRoot(.number(4))), 0.5),
                UnitTest(.square(.inverse(.squareRoot(.number(4)))), 0.25),
                UnitTest(.squareRoot(.inverse(.square(.number(4)))), 0.25),
                UnitTest(.inverse(.number(.infinity)), 0.0),
                UnitTest(.inverse(.number(-.infinity)), 0.0),
                UnitTest(.inverse(.number(0)), .infinity)
            ]),
            
            "Error: Root" : (.equivalent, [
                UnitTest(.root(.number(.nan), .number(1)), .nan),
                UnitTest(.root(.number(1), .number(.nan)), .nan),
                UnitTest(.root(.number(-.nan), .number(0.1)), .nan),
                UnitTest(.root(.number(0.1), .number(-.nan)), .nan),
                UnitTest(.root(.number(2), .number(-1)), -.nan),
            ]),
            
            "Root General" : (.equivalent, [
                UnitTest(.root(.number(0), .number(0)), 0),
                UnitTest(.root(.number(0), .number(1)), 1),
                UnitTest(.root(.number(0), .number(0.1)), 0),
                UnitTest(.root(.number(1), .number(0.1)), 0.1),
                UnitTest(.root(.number(2), .number(0.01)), 0.1),
                UnitTest(.root(.number(2), .number(100)), 10),
                UnitTest(.root(.number(3), .number(-1)), -1),
                UnitTest(.root(.number(.infinity), .number(0)), 1),
                UnitTest(.root(.number(-.infinity), .number(0)), 1),
                UnitTest(.root(.number(.infinity), .number(.infinity)), 1),
                UnitTest(.root(.number(-.infinity), .number(.infinity)), 1),
                UnitTest(.root(.number(0), .number(.infinity)), .infinity),
                UnitTest(.root(.number(0), .number(-.infinity)), .infinity),
            ]),
            
            // I want to make sure that the accuracy for odd roots is exactly what we expect from even roots (just to show consistency.)
            // Double.greatestFiniteMagnitude = 1.7976931348623157e+308, so let's test up to the 2 largest exponent products of 10 for Double. This should be no problem for Float80.
            "Root Positive Whole" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1), .number(10.0)), 10),
                UnitTest(.root(.number(2), .number(100.0)), 10),
                UnitTest(.root(.number(3), .number(1000.0)), 10),
                UnitTest(.root(.number(4), .number(10000.0)), 10),
                UnitTest(.root(.number(5), .number(100000.0)), 10),
                UnitTest(.root(.number(10), .number(10000000000.0)), 10),
                UnitTest(.root(.number(11), .number(100000000000.0)), 10),
                UnitTest(.root(.number(20), .number(100000000000000000000.0)), 10),
                UnitTest(.root(.number(21), .number(1000000000000000000000.0)), 10),
                UnitTest(.root(.number(40), .number(10000000000000000000000000000000000000000.0)), 10),
                UnitTest(.root(.number(41), .number(100000000000000000000000000000000000000000.0)), 10),
                UnitTest(.root(.number(80), .number(100000000000000000000000000000000000000000000000000000000000000000000000000000000.0)), 10),
                UnitTest(.root(.number(81), .number(1000000000000000000000000000000000000000000000000000000000000000000000000000000000.0)), 10),
                UnitTest(.root(.number(160), .number(10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0)), 10),
                UnitTest(.root(.number(161), .number(100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0)), 10),
                UnitTest(.root(.number(307), .number(10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0)), 10),
                UnitTest(.root(.number(308), .number(100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0)), 10),
            ]),

            // And similarly for negative numbers.
            "Root Negative Whole" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1), .negation(.number(10.0))), -10),
                UnitTest(.root(.number(3), .negation(.number(1000.0))), -10),
                UnitTest(.root(.number(5), .negation(.number(100000.0))), -10),
                UnitTest(.root(.number(11), .negation(.number(100000000000.0))), -10),
                UnitTest(.root(.number(21), .negation(.number(1000000000000000000000.0))), -10),
                UnitTest(.root(.number(41), .negation(.number(100000000000000000000000000000000000000000.0))), -10),
                UnitTest(.root(.number(81), .negation(.number(1000000000000000000000000000000000000000000000000000000000000000000000000000000000.0))), -10),
                UnitTest(.root(.number(161), .negation(.number(100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0))), -10),
                UnitTest(.root(.number(307), .negation(.number(10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000.0))), -10),
            ]),
            
            // Let's go the other way too, up to Double.leastNonzeroMagnitude = 5e-324. We should hit the accuracy threshold easily with Float80.
            "Root Positive Decimal" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1), .number(0.1)), 0.1),
                UnitTest(.root(.number(2), .number(0.01)), 0.1),
                UnitTest(.root(.number(3), .number(0.001)), 0.1),
                UnitTest(.root(.number(4), .number(0.0001)), 0.1),
                UnitTest(.root(.number(5), .number(0.00001)), 0.1),
                UnitTest(.root(.number(10), .number(0.0000000001)), 0.1),
                UnitTest(.root(.number(11), .number(0.00000000001)), 0.1),
                UnitTest(.root(.number(20), .number(0.00000000000000000001)), 0.1),
                UnitTest(.root(.number(21), .number(0.000000000000000000001)), 0.1),
                UnitTest(.root(.number(40), .number(0.0000000000000000000000000000000000000001)), 0.1),
                UnitTest(.root(.number(41), .number(0.00000000000000000000000000000000000000001)), 0.1),
                UnitTest(.root(.number(80), .number(0.00000000000000000000000000000000000000000000000000000000000000000000000000000001)), 0.1),
                UnitTest(.root(.number(81), .number(0.000000000000000000000000000000000000000000000000000000000000000000000000000000001)), 0.1),
                UnitTest(.root(.number(160), .number(0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001)), 0.1),
                UnitTest(.root(.number(161), .number(0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001)), 0.1),
                UnitTest(.root(.number(308), .number(0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001)), 0.1),
                UnitTest(.root(.number(309), .number(0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001)), 0.1),
            ]),
            
            // And similarly for negative decimals.
            "Root Negative Decimal" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1), .negation(.number(0.1))), -0.1),
                UnitTest(.root(.number(3), .negation(.number(0.001))), -0.1),
                UnitTest(.root(.number(5), .negation(.number(0.00001))), -0.1),
                UnitTest(.root(.number(11), .negation(.number(0.00000000001))), -0.1),
                UnitTest(.root(.number(21), .negation(.number(0.00000000000000000001))), -0.1),
                UnitTest(.root(.number(41), .negation(.number(0.000000000000000000000000000000000000000001))), -0.1),
                UnitTest(.root(.number(81), .negation(.number(0.0000000000000000000000000000000000000000000000000000000000000000000000000000000001))), -0.1),
                UnitTest(.root(.number(161), .negation(.number(0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001))), -0.1),
                UnitTest(.root(.number(309), .negation(.number(0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001))), -0.1),
            ]),
            
            /** Rank (from most important to least):
             *  -1. Parenthesis
             *  0. abs, sum
             *  1. factorial
             *  2. exponent
             **/
            
            // TODO: Complete function unit tests
        ]
        
        evaluateTestCaseSuite(testCaseSuite, using: { input in
            return input.evaluate()
        })
    }
    
    func evaluateTestCaseSuite<I, O: UnitTestOutput>(_ testCaseSuite: [String : (SuccessCondition, [TemplateTest<I, O>])], using outputClosure: (I) -> O) {
        for (section, (condition, testCases)) in testCaseSuite {
            for (index, testCase) in testCases.enumerated() {
                let output = outputClosure(testCase.input)
                
                switch condition {
                case .approximate(within: let threshold):
                    let outputError = output |-| testCase.output
                    XCTAssert(outputError <= threshold, String(format: "Test Case \(index + 1) in '\(section)' Failed.\nExpected: \(testCase.output),\n\t  Saw: \(outputError) > \(threshold) for \(output)"))
                case .equivalent:
                    XCTAssert(output == testCase.output || output.isNaN() && testCase.output.isNaN(), String(format: "Test Case \(index + 1) in '\(section)' Failed.\nExpected: \(testCase.output),\n\t  Saw: \(output)"))
                }
            }
        }
    }
}



//            UnitTest(.multiplication(.number(1), .error), .nan),
//            UnitTest(.multiplication(.error, .number(1)), .nan),
//            UnitTest(.multiplication(.number(1), .number(2)), 2),
//            UnitTest(.multiplication(.number(2), .negation(.number(3))), -6),
//            UnitTest(.multiplication(.addition(.number(2), .number(4)), .subtraction(.number(2), .number(5))), -18),
//            UnitTest(.division(.number(1), .error), .nan),
//            UnitTest(.division(.error, .number(1)), .nan),
//            UnitTest(.division(.number(1), .number(0)), .infinity),
//            UnitTest(.division(.number(1), .number(.infinity)), 0),
//            UnitTest(.division(.number(.infinity), .number(.infinity)), -.nan),
//            UnitTest(.division(.number(0), .number(.infinity)), 0),
//            UnitTest(.division(.number(1), .number(2)), 0.5),
//            UnitTest(.exponentiation(.error, .number(2)), .nan),
//            UnitTest(.exponentiation(.number(1), .error), .nan),
//            UnitTest(.exponentiation(.number(4), .number(0.5)), 2),
//            UnitTest(.exponentiation(.number(3), .number(0)), 1),
//            UnitTest(.exponentiation(.number(.infinity), .number(0)), 1),
//            UnitTest(.exponentiation(.number(0), .number(.infinity)), 0)

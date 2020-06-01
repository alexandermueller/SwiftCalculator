//
//  ArithmeticExpressionTests.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2019-09-30.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import Calculator

typealias TemplateTest<I, O: ImplementsIsNaN> = (input: I, output: O)

class ArithmeticExpressionTests: XCTestCase {
    func testParseExpression() {
        typealias UnitTest = TemplateTest<[String], ArithmeticExpression>
        
        let testCaseSuite: [String : [UnitTest]] = [
            "Empty" : [
                UnitTest([], .empty)
            ],
            
            "Number, Double" : [
                UnitTest(["0."], .error),
                UnitTest(["1"], .number(1)),
                UnitTest(["0.000001"], .number(0.000001))
            ],
            
            "Addition" : [
                UnitTest(["0", "+"], .error),
                UnitTest(["0", "+", "0."], .error),
                UnitTest(["1", "+", "2"], .addition(.number(1), .number(2))),
                UnitTest(["1", "+", "2", "+", "1", "+", "2"], .addition(.addition(.addition(.number(1), .number(2)), .number(1)), .number(2)))
            ],
            
            "Subtraction" : [
                UnitTest(["0", "-"], .error),
                UnitTest(["0", "-", "0."], .error),
                UnitTest(["1", "–", "1"], .subtraction(.number(1), .number(1))),
                UnitTest(["1", "+", "2", "+", "1", "+", "2"], .addition(.addition(.addition(.number(1), .number(2)), .number(1)), .number(2)))
            ],
            
            "Addition + Subtraction" : [
                UnitTest(["1", "+", "1", "–", "1"], .subtraction(.addition(.number(1), .number(1)), .number(1))),
                UnitTest(["1", "–", "1", "+", "1"], .addition(.subtraction(.number(1), .number(1)), .number(1)))
            ],
            
            "Modulo" : [
                UnitTest(["0", "%"], .error),
                UnitTest(["0", "%", "0."], .error),
                UnitTest(["1", "+", "1", "%", "1"], .addition(.number(1), .modulo(.number(1), .number(1)))),
                UnitTest(["1", "%", "1", "–", "1"], .subtraction(.modulo(.number(1), .number(1)), .number(1))),
                UnitTest(["3", "%", "4", "%", "5"], .modulo(.modulo(.number(3), .number(4)), .number(5)))
            ],
            
            "Negation" : [
                UnitTest(["-"], .error),
                UnitTest(["-", "1"], .negation(.number(1))),
                UnitTest(["-", "-", "1"], .negation(.negation(.number(1)))),
                UnitTest(["-", "1", "–", "1"], .subtraction(.negation(.number(1)), .number(1))),
            ],
            
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
        typealias UnitTest = TemplateTest<ArithmeticExpression, Double>
        
        let testCaseSuite: [String : [UnitTest]] = [
            "Empty, Error, NaN" : [
                UnitTest(.empty, .nan),
                UnitTest(.error, .nan),
                UnitTest(.number(.nan), .nan)
            ],
            
            "Number, Double, Infinity" : [
                UnitTest(.number(2), 2),
                UnitTest(.number(-3), -3),
                UnitTest(.number(-0.1), -0.1),
                UnitTest(.number(.infinity), .infinity),
                UnitTest(.number(-.infinity), -.infinity)
            ],
            
            "Negation" : [
                UnitTest(.negation(.number(.nan)), .nan),
                UnitTest(.negation(.number(.infinity)), -.infinity),
                UnitTest(.negation(.number(-.infinity)), .infinity),
                UnitTest(.negation(.number(0)), 0),
                UnitTest(.negation(.number(1)), -1),
                UnitTest(.negation(.negation(.number(1))), 1)
            ],
            
            "Error: Addition, Subtraction" : [
                UnitTest(.addition(.number(.nan), .number(1)), .nan),
                UnitTest(.addition(.number(1), .number(.nan)), .nan),
                UnitTest(.addition(.number(.infinity), .number(-.infinity)), -.nan),
                UnitTest(.subtraction(.number(.infinity), .number(.infinity)), -.nan),
                UnitTest(.subtraction(.number(.infinity), .number(.infinity)), -.nan),
                UnitTest(.subtraction(.number(-.infinity), .number(-.infinity)), -.nan),
                UnitTest(.subtraction(.number(.nan), .number(3)), .nan),
                UnitTest(.subtraction(.number(3), .number(.nan)), .nan)
            ],
            
            "Addition, Subtraction": [
                UnitTest(.addition(.number(1), .number(2)), 3),
                UnitTest(.subtraction(.number(2), .number(3)), -1),
                UnitTest(.addition(.subtraction(.number(1), .number(4)), .number(3)), 0),
                UnitTest(.addition(.number(.infinity), .number(.infinity)), .infinity),
                UnitTest(.addition(.number(-.infinity), .number(-.infinity)), -.infinity),
                UnitTest(.addition(.negation(.number(1)), .number(1)), 0),
                UnitTest(.addition(.negation(.number(1)), .negation(.number(1))), -2),
                UnitTest(.subtraction(.negation(.number(1)), .number(1)), -2),
                UnitTest(.subtraction(.number(1), .negation(.number(1))), 2)
            ],
            
            "Error: Modulo" : [
                UnitTest(.modulo(.number(.nan), .number(1)), .nan),
                UnitTest(.modulo(.number(1), .number(.nan)), .nan),
                UnitTest(.modulo(.number(.infinity), .number(1)), .nan),
                UnitTest(.modulo(.number(-.infinity), .number(1)), -.nan),
                UnitTest(.modulo(.number(.infinity), .number(.infinity)), .nan),
                UnitTest(.modulo(.number(-.infinity), .number(-.infinity)), .nan),
                UnitTest(.modulo(.number(.infinity), .number(-.infinity)), -.nan),
                UnitTest(.modulo(.number(-.infinity), .number(.infinity)), -.nan),
                UnitTest(.modulo(.number(1), .number(0)), .nan)
            ],
            
            "Modulo" : [
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
            ],
            
            "Error: Multiplication, Division" : [
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
            ],
            
            "Multiplication" : [
                UnitTest(.multiplication(.number(0), .number(0)), 0),
                UnitTest(.multiplication(.number(1), .number(0)), 0),
                UnitTest(.multiplication(.negation(.number(1)), .number(0)), 0),
                UnitTest(.multiplication(.number(1), .number(1)), 1),
                UnitTest(.multiplication(.number(1), .number(2)), 2),
                UnitTest(.multiplication(.number(2), .number(0.5)), 1),
                UnitTest(.multiplication(.negation(.number(1)), .number(2)), -2),
                UnitTest(.multiplication(.number(.infinity), .number(.infinity)), .infinity),
                UnitTest(.multiplication(.number(.infinity), .number(-.infinity)), -.infinity)
            ],
            
            "Division" : [
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
            ],
            
            "Multiplication + Division" : [
                UnitTest(.multiplication(.division(.number(1), .number(2)), .number(2)), 1),
                UnitTest(.multiplication(.number(2), .division(.number(1), .number(2))), 1),
                UnitTest(.division(.multiplication(.number(1), .number(2)), .number(2)), 1),
                UnitTest(.division(.number(2), .multiplication(.number(1), .number(2))), 1)
            ],
            
            "Error: Square Root, Inverse, Square" : [
                UnitTest(.squareRoot(.number(.nan)), .nan),
                UnitTest(.squareRoot(.number(-.nan)), .nan),
                UnitTest(.squareRoot(.negation(.number(1))), -.nan),
                UnitTest(.squareRoot(.number(-.infinity)), -.nan),
                UnitTest(.square(.number(.nan)), .nan),
                UnitTest(.square(.number(-.nan)), .nan),
                UnitTest(.inverse(.number(.nan)), .nan),
                UnitTest(.inverse(.number(-.nan)), .nan),
            ],
            
            "Square Root" : [
                UnitTest(.squareRoot(.number(0)), 0),
                UnitTest(.squareRoot(.number(1)), 1),
                UnitTest(.squareRoot(.number(9)), 3),
                UnitTest(.squareRoot(.number(.infinity)), .infinity),
                UnitTest(.squareRoot(.square(.number(9))), 9),
                UnitTest(.squareRoot(.square(.number(100))), 100),
                UnitTest(.squareRoot(.square(.number(10000000000))), 10000000000),
                UnitTest(.squareRoot(.square(.number(10000000000.0000000001))), 10000000000.0000000001),
                UnitTest(.squareRoot(.square(.number(.infinity))), .infinity)
            ],
            
            "Square" : [
                UnitTest(.square(.number(0)), 0),
                UnitTest(.square(.number(1)), 1),
                UnitTest(.square(.number(3)), 9),
                UnitTest(.square(.number(-.infinity)), .infinity),
                UnitTest(.square(.squareRoot(.number(9))), 9),
                UnitTest(.square(.squareRoot(.number(100))), 100),
                UnitTest(.square(.squareRoot(.number(10000000000))), 10000000000),
                UnitTest(.square(.squareRoot(.number(10000000000.0000000001))), 10000000000.0000000001),
                UnitTest(.square(.squareRoot(.number(.infinity))), .infinity)
            ],
            
            "Inverse" : [
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
            ],
            
            "Error: Root" : [
                UnitTest(.root(.number(.nan), .number(1)), .nan),
                UnitTest(.root(.number(1), .number(.nan)), .nan),
                UnitTest(.root(.number(-.nan), .number(0.1)), .nan),
                UnitTest(.root(.number(0.1), .number(-.nan)), .nan),
            ],
            
            "Root" : [
                UnitTest(.root(.number(0), .number(0)), 0),
                UnitTest(.root(.number(0), .number(1)), 1),
                UnitTest(.root(.number(0) , .number(0.1)), 0),
                UnitTest(.root(.number(0), .number(.infinity)), .infinity),
                UnitTest(.root(.number(0), .number(-.infinity)), .infinity),
                UnitTest(.root(.number(.infinity), .number(0)), 1),
                UnitTest(.root(.number(.infinity), .number(.infinity)), 1),
            ],
            
            /** Rank (from most important to least):
             *  0. abs, sum
             *  1. factorial
             *  2. exponent
             *  3. root
             **/
            
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
            // TODO: Complete function unit tests
        ]
        
        evaluateTestCaseSuite(testCaseSuite, using: { input in
            return input.evaluate()
        })
    }
    
    func evaluateTestCaseSuite<I, O: ImplementsIsNaN>(_ testCaseSuite: [String : [TemplateTest<I, O>]], using outputClosure: (I) -> O) {
        for (section, testCases) in testCaseSuite {
            for (index, testCase) in testCases.enumerated() {
                let output = outputClosure(testCase.input)
                XCTAssert(output == testCase.output || output.isNaN() && testCase.output.isNaN(), String(format: "Test Case \(index + 1) in '\(section)' Failed.\nExpected: \(testCase.output),\n\t  Saw: \(output)"))
            }
        }
    }
}

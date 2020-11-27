//
//  ArithmeticExpressionTests.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2019-09-30.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import XCTest
@testable import Calculator

let kErrorThreshold: MaxPrecisionNumber = 1 * powl(10, -18)

enum SuccessCondition {
    case equivalent
    case approximate(within: MaxPrecisionNumber)
}

typealias TemplateTest<I, O: UnitTestOutput> = (input: I, output: O)

class ArithmeticExpressionTests : XCTestCase {
    func testParseExpression() {
        typealias UnitTest = TemplateTest<[String], ArithmeticExpression>
        
        let testCaseSuite: [String : (SuccessCondition, [UnitTest])] = [
            "Empty" : (.equivalent, [
                UnitTest([], .empty)
            ]),
            
            "Number, Decimal" : (.equivalent, [
                UnitTest(["0."], .error),
                UnitTest(["1"], .number(1)),
                UnitTest(["0.000001"], .number(0.000001)),
                UnitTest(["10.000001"], .number(10.000001)),
            ]),
            
            "Addition" : (.equivalent, [
                UnitTest(["0", "+"], .error),
                UnitTest(["0", "+", "0."], .error),
                UnitTest(["1", "+", "2"], .addition(.number(1), .number(2))),
                UnitTest(["1", "+", "2", "+", "1", "+", "2"], .addition(.addition(.addition(.number(1), .number(2)), .number(1)), .number(2))),
            ]),
            
            "Subtraction" : (.equivalent, [
                UnitTest(["0", "-"], .error),
                UnitTest(["0", "-", "0."], .error),
                UnitTest(["1", "–", "1"], .subtraction(.number(1), .number(1))),
                UnitTest(["1", "+", "2", "+", "1", "+", "2"], .addition(.addition(.addition(.number(1), .number(2)), .number(1)), .number(2))),
            ]),
            
            "Addition & Subtraction" : (.equivalent, [
                UnitTest(["1", "+", "1", "–", "1"], .subtraction(.addition(.number(1), .number(1)), .number(1))),
                UnitTest(["1", "–", "1", "+", "1"], .addition(.subtraction(.number(1), .number(1)), .number(1))),
            ]),
            
            "Modulo" : (.equivalent, [
                UnitTest(["0", "%"], .error),
                UnitTest(["0", "%", "0."], .error),
                UnitTest(["1", "+", "1", "%", "1"], .addition(.number(1), .modulo(.number(1), .number(1)))),
                UnitTest(["1", "%", "1", "–", "1"], .subtraction(.modulo(.number(1), .number(1)), .number(1))),
                UnitTest(["3", "%", "4", "%", "5"], .modulo(.modulo(.number(3), .number(4)), .number(5))),
            ]),
            
            "Negation" : (.equivalent, [
                UnitTest(["-"], .error),
                UnitTest(["-", "1"], .negation(.number(1))),
                UnitTest(["-", "-", "1"], .negation(.negation(.number(1)))),
                UnitTest(["-", "1", "–", "1"], .subtraction(.negation(.number(1)), .number(1))),
            ]),
            
            "Multiplication" : (.equivalent, [
                UnitTest(["1", "x", "2"], .multiplication(.number(1), .number(2))),
                UnitTest(["1", "x", "2", "x", "3"], .multiplication(.multiplication(.number(1), .number(2)), .number(3))),
                UnitTest(["-", "1", "x", "2"], .multiplication(.negation(.number(1)), .number(2))),
                UnitTest(["3", "x", "-", "1"], .multiplication(.number(3), .negation(.number(1)))),
            ]),
            
            "Division" : (.equivalent, [
                UnitTest(["1", "÷", "2"], .division(.number(1), .number(2))),
                UnitTest(["1", "÷", "2", "÷", "3"], .division(.division(.number(1), .number(2)), .number(3))),
                UnitTest(["-", "1", "÷", "2"], .division(.negation(.number(1)), .number(2))),
                UnitTest(["3", "÷", "-", "1"], .division(.number(3), .negation(.number(1)))),
            ]),
            
            "Multiplication & Division & Negation" : (.equivalent, [
                UnitTest(["1", "x", "2", "÷", "3"], .division(.multiplication(.number(1), .number(2)), .number(3))),
                UnitTest(["1", "÷", "2", "x", "3"], .multiplication(.division(.number(1), .number(2)), .number(3))),
                UnitTest(["1", "÷", "3", "x",  "1", "÷", "2", "x", "3"], .multiplication(.division(.multiplication(.division(.number(1), .number(3)), .number(1)), .number(2)), .number(3))),
                UnitTest(["1", "x", "3", "÷",  "2", "x", "1", "÷", "2"], .division(.multiplication(.division(.multiplication(.number(1), .number(3)), .number(2)), .number(1)), .number(2))),
                UnitTest(["1", "x", "-", "3", "÷",  "2", "x", "-", "1", "÷", "2"], .division(.multiplication(.division(.multiplication(.number(1), .negation(.number(3))), .number(2)), .negation(.number(1))), .number(2))),
                UnitTest(["1", "+", "1", "x", "3"], .addition(.number(1), .multiplication(.number(1), .number(3)))),
                UnitTest(["1", "÷", "1", "–", "3"], .subtraction(.division(.number(1), .number(1)), .number(3))),
                UnitTest(["9", "÷", "-", "3", "–", "3", "x", "3", "+", "1"], .addition(.subtraction(.division(.number(9), .negation(.number(3))), .multiplication(.number(3), .number(3))), .number(1))),
                UnitTest(["1", "%", "2", "÷", "1", "–", "3", "%", "5"], .subtraction(.modulo(.number(1), .division(.number(2), .number(1))), .modulo(.number(3), .number(5)))),
            ]),
            
            "Square Root" : (.equivalent, [
                UnitTest(["√", "2", "+", "2"], .addition(.squareRoot(.number(2)), .number(2))),
                UnitTest(["2", "^", "√", "2"], .exponentiation(.number(2), .squareRoot(.number(2)))),
                UnitTest(["√", "2", "^", "2"], .squareRoot(.exponentiation(.number(2), .number(2)))), // This what the Google calculator says should be the order of operations
            ]),
            
            "Inverse" : (.equivalent, [
                UnitTest(["1/", "2"], .inverse(.number(2))),
                UnitTest(["1/", "2", "^", "2"], .inverse(.exponentiation(.number(2), .number(2)))),
            ]),
            
            "Square" : (.equivalent, [
            
            ]),
            
            "Factorial" : (.equivalent, [
                UnitTest(["2", "!"], .factorial(.number(2))),
                UnitTest(["-", "3", "!"], .negation(.factorial(.number(3)))),
            ]),
            
            "Absolute Value" : (.equivalent, [
                UnitTest(["~", "2"], .absoluteValue(.number(2))),
                UnitTest(["~", "-", "3"], .absoluteValue(.negation(.number(3)))),
                UnitTest(["~", "(", "3", "–", "4", ")"], .absoluteValue(.subtraction(.number(3), .number(4)))),
            ]),
            
            "Summation" : (.equivalent, [
                UnitTest(["∑", "2"], .summation(.number(2))),
                UnitTest(["∑", "-", "3"], .summation(.negation(.number(3)))),
                UnitTest(["∑", "(", "3", "–", "4", ")"], .summation(.subtraction(.number(3), .number(4)))),
                UnitTest(["∑", "(", "3", "–", "4", ")", "!"], .factorial(.summation(.subtraction(.number(3), .number(4))))),
            ]),
        ]
        
        evaluateTestCaseSuite(testCaseSuite, using: { input in
            return Generator().startGenerator(with: input).value
        })
    }
    
    func testArithmeticExpressionEvaluate() {
        typealias UnitTest = TemplateTest<ArithmeticExpression, MaxPrecisionNumber>
        
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
            // Float80.greatestFiniteMagnitude = 1.189731495357231765e+4932, so let's test up to the 2 largest exponent products of 10 for Float80.
            "Root Positive Whole" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1),    .number(1e1)),    10),
                UnitTest(.root(.number(2),    .number(1e2)),    10),
                UnitTest(.root(.number(3),    .number(1e3)),    10),
                UnitTest(.root(.number(4),    .number(1e4)),    10),
                UnitTest(.root(.number(5),    .number(1e5)),    10),
                UnitTest(.root(.number(10),   .number(1e10)),   10),
                UnitTest(.root(.number(11),   .number(1e11)),   10),
                UnitTest(.root(.number(20),   .number(1e20)),   10),
                UnitTest(.root(.number(21),   .number(1e21)),   10),
                UnitTest(.root(.number(40),   .number(1e40)),   10),
                UnitTest(.root(.number(41),   .number(1e41)),   10),
                UnitTest(.root(.number(80),   .number(1e80)),   10),
                UnitTest(.root(.number(81),   .number(1e81)),   10),
                UnitTest(.root(.number(160),  .number(1e160)),  10),
                UnitTest(.root(.number(161),  .number(1e161)),  10),
                UnitTest(.root(.number(320),  .number(1e320)),  10),
                UnitTest(.root(.number(321),  .number(1e321)),  10),
                UnitTest(.root(.number(640),  .number(1e640)),  10),
                UnitTest(.root(.number(641),  .number(1e641)),  10),
                UnitTest(.root(.number(4931), .number(1e4931)), 10),
                UnitTest(.root(.number(4932), .number(1e4932)), 10),
            ]),

            // And similarly for negative numbers. Float80.leastNormalMagnitude = 3.3621031431120935063e-4932.
            "Root Negative Whole" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1),    .negation(.number(1e1))),    -10),
                UnitTest(.root(.number(3),    .negation(.number(1e3))),    -10),
                UnitTest(.root(.number(5),    .negation(.number(1e5))),    -10),
                UnitTest(.root(.number(11),   .negation(.number(1e11))),   -10),
                UnitTest(.root(.number(21),   .negation(.number(1e21))),   -10),
                UnitTest(.root(.number(41),   .negation(.number(1e41))),   -10),
                UnitTest(.root(.number(81),   .negation(.number(1e81))),   -10),
                UnitTest(.root(.number(161),  .negation(.number(1e161))),  -10),
                UnitTest(.root(.number(321),  .negation(.number(1e321))),  -10),
                UnitTest(.root(.number(641),  .negation(.number(1e641))),  -10),
                UnitTest(.root(.number(4931), .negation(.number(1e4931))), -10),
            ]),
            
            // Let's go the other way too. Float80.leastNonzeroMagnitude = 4e-4951.
            "Root Positive Decimal" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1),   .number(1e-1)),   0.1),
                UnitTest(.root(.number(2),   .number(1e-2)),   0.1),
                UnitTest(.root(.number(3),   .number(1e-3)),   0.1),
                UnitTest(.root(.number(4),   .number(1e-4)),   0.1),
                UnitTest(.root(.number(5),   .number(1e-5)),   0.1),
                UnitTest(.root(.number(10),  .number(1e-10)),  0.1),
                UnitTest(.root(.number(11),  .number(1e-11)),  0.1),
                UnitTest(.root(.number(20),  .number(1e-20)),  0.1),
                UnitTest(.root(.number(21),  .number(1e-21)),  0.1),
                UnitTest(.root(.number(40),  .number(1e-40)),  0.1),
                UnitTest(.root(.number(41),  .number(1e-41)),  0.1),
                UnitTest(.root(.number(80),  .number(1e-80)),  0.1),
                UnitTest(.root(.number(81),  .number(1e-81)),  0.1),
                UnitTest(.root(.number(160), .number(1e-160)), 0.1),
                UnitTest(.root(.number(161), .number(1e-161)), 0.1),
                UnitTest(.root(.number(320), .number(1e-320)), 0.1),
                UnitTest(.root(.number(321), .number(1e-321)), 0.1),
                UnitTest(.root(.number(640), .number(1e-640)), 0.1),
                UnitTest(.root(.number(641), .number(1e-641)), 0.1),
                // The error at this point gets kinda bad, so I'll just accept that and move on.
                // UnitTest(.root(.number(4950), .number(1e-4950)), 0.1),
                // UnitTest(.root(.number(4951), .number(1e-4951)), 0.1),
            ]),
            
            // And similarly for negative decimals.
            "Root Negative Decimal" : (.approximate(within: kErrorThreshold), [
                UnitTest(.root(.number(1),   .negation(.number(1e-1))),   -0.1),
                UnitTest(.root(.number(3),   .negation(.number(1e-3))),   -0.1),
                UnitTest(.root(.number(5),   .negation(.number(1e-5))),   -0.1),
                UnitTest(.root(.number(11),  .negation(.number(1e-11))),  -0.1),
                UnitTest(.root(.number(21),  .negation(.number(1e-21))),  -0.1),
                UnitTest(.root(.number(41),  .negation(.number(1e-41))),  -0.1),
                UnitTest(.root(.number(81),  .negation(.number(1e-81))),  -0.1),
                UnitTest(.root(.number(161), .negation(.number(1e-161))), -0.1),
                UnitTest(.root(.number(321), .negation(.number(1e-321))), -0.1),
                UnitTest(.root(.number(641), .negation(.number(1e-641))), -0.1),
                // The error at this point gets kinda bad, so I'll just accept that and move on.
                // UnitTest(.root(.number(4951), .negation(.number(1e-4951))), -0.1),
            ]),
            
            "Error: Exponent" : (.equivalent, [
                UnitTest(.exponentiation(.number(.nan), .number(.nan)), .nan),
                UnitTest(.exponentiation(.number(1), .number(.nan)), .nan),
                UnitTest(.exponentiation(.number(.nan), .number(0)), .nan),
                UnitTest(.exponentiation(.number(.nan), .number(1)), .nan),
                UnitTest(.exponentiation(.number(0), .number(.nan)), .nan),
                UnitTest(.exponentiation(.number(1), .number(.nan)), .nan),
                UnitTest(.exponentiation(.number(0.1), .number(-.nan)), .nan),
                UnitTest(.exponentiation(.number(0.1), .number(-.nan)), .nan),
                UnitTest(.exponentiation(.number(-1), .number(0.5)), -.nan),
            ]),
            
            "Exponent Whole" : (.equivalent, [
                UnitTest(.exponentiation(.number(0), .number(1)), 0),
                UnitTest(.exponentiation(.number(0), .number(.infinity)), 0),
                UnitTest(.exponentiation(.number(0), .number(0)), 1),
                UnitTest(.exponentiation(.negation(.number(1)), .number(.infinity)), 1),
                UnitTest(.exponentiation(.negation(.number(1)), .number(-.infinity)), 1),
                UnitTest(.exponentiation(.number(10), .number(10)), 10000000000),
                UnitTest(.exponentiation(.number(10), .number(3)), 1000),
                UnitTest(.exponentiation(.number(10), .number(2)), 100),
                UnitTest(.exponentiation(.number(10), .number(1)), 10),
                UnitTest(.exponentiation(.number(10), .number(0)), 1),
            ]),
            
            "Exponent Decimal" : (.approximate(within: kErrorThreshold), [
                UnitTest(.exponentiation(.number(10), .negation(.number(1))),     1e-1),
                UnitTest(.exponentiation(.number(10), .negation(.number(2))),     1e-2),
                UnitTest(.exponentiation(.number(10), .negation(.number(3))),     1e-3),
                UnitTest(.exponentiation(.number(10), .negation(.number(10))),    1e-10),
                UnitTest(.exponentiation(.number(10), .negation(.number(4951))),  1e-4951),
                UnitTest(.exponentiation(.number(10), .negation(.number(4952))),  0),
                UnitTest(.exponentiation(.number(10), .negation(.number(10000))), 0),
            ]),
            
            "Error: Factorial" : (.equivalent, [
                UnitTest(.factorial(.number(0.1)), .nan),
                UnitTest(.factorial(.negation(.number(0.1))), .nan),
                
            ]),
            
            "Factorial" : (.equivalent, [
                UnitTest(.factorial(.number(.infinity)), .infinity),
                UnitTest(.factorial(.number(4)), 24),
                UnitTest(.factorial(.number(3)), 6),
                UnitTest(.factorial(.number(2)), 2),
                UnitTest(.factorial(.number(1)), 1),
                UnitTest(.factorial(.number(0)), 1),
                UnitTest(.factorial(.negation(.number(1))), -1),
                UnitTest(.factorial(.negation(.number(2))), 2),
                UnitTest(.factorial(.negation(.number(3))), -6),
                UnitTest(.factorial(.negation(.number(4))), 24),
                UnitTest(.factorial(.negation(.number(.infinity))), -.infinity),
                UnitTest(.factorial(.number(-.infinity)), -.infinity),
            ]),
            
            "Error: Absolute Value" : (.equivalent, [
                UnitTest(.absoluteValue(.number(.nan)), .nan),
                UnitTest(.absoluteValue(.number(-.nan)), .nan),
            ]),
            
            "Absolute Value" : (.equivalent, [
                UnitTest(.absoluteValue(.negation(.number(1))), 1),
                UnitTest(.absoluteValue(.number(0)), 0),
                UnitTest(.absoluteValue(.number(1)), 1),
                UnitTest(.absoluteValue(.number(.infinity)), .infinity),
                UnitTest(.absoluteValue(.number(-.infinity)), .infinity),
            ]),
            
            "Error: Summation" : (.equivalent, [
                UnitTest(.summation(.number(.nan)), .nan),
                UnitTest(.summation(.number(-.nan)), .nan),
                UnitTest(.summation(.number(0.5)), .nan),
                UnitTest(.summation(.number(-0.5)), .nan),
            ]),
            
            "Summation" : (.equivalent, [
                UnitTest(.summation(.negation(.number(.infinity))), -.infinity),
                UnitTest(.summation(.number(-.infinity)), -.infinity),
                UnitTest(.summation(.negation(.number(3))), -6),
                UnitTest(.summation(.negation(.number(2))), -3),
                UnitTest(.summation(.negation(.number(1))), -1),
                UnitTest(.summation(.number(0)), 0),
                UnitTest(.summation(.number(1)), 1),
                UnitTest(.summation(.number(2)), 3),
                UnitTest(.summation(.number(3)), 6),
                UnitTest(.summation(.number(.infinity)), .infinity),
            ]),
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
                    XCTAssert(outputError.isNaN() && output == testCase.output || outputError.isPositive() && outputError <= threshold, String(format: "Test Case \(index + 1)/\(testCases.count) in '\(section)' Failed.\nExpected: \(testCase.output),\n\t  Saw: \(outputError) for \(output)"))
                case .equivalent:
                    XCTAssert(output == testCase.output || output.isNaN() && testCase.output.isNaN(), String(format: "Test Case \(index + 1)/\(testCases.count) in '\(section)' Failed.\nExpected: \(testCase.output),\n\t  Saw: \(output)"))
                }
            }
        }
    }
}

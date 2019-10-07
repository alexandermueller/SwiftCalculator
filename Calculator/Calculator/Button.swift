//
//  Button.swift
//  Calculator
//
//  Created by Alex Mueller on 2019-10-04.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

enum Digit: String, CaseIterable {
    case zero = "0"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
}

enum Modifier: String, CaseIterable {
    case decimal = "."
}

enum Parenthesis: String, CaseIterable {
    case open = "("
    case close = ")"
}

enum Left: String, CaseIterable {
    case negate = "-"
    case sqrt = "√"
}

enum Middle: String, CaseIterable {
    case add = "+"
    case subtract = "–"
    case multiply = "x"
    case divide = "÷"
    case exponent = "^"
    case root = "*√"
}

enum Right: String, CaseIterable {
    case factorial = "!"
}

// NOTE: This has been sorted by increasing order of precedence.
enum Function: Equatable {
    case left(Left)
    case middle(Middle)
    case right(Right)
    
    static func from(rawValue: String) -> Function? {
        if let left = Left(rawValue: rawValue) {
            return .left(left)
        } else if let middle = Middle(rawValue: rawValue) {
            return .middle(middle)
        } else if let right = Right(rawValue: rawValue) {
            return .right(right)
        }
        
        return nil
    }
    
    // Highest to lowest precedence
    static func allCasesOrdered() -> [Function] {
        return [.right(.factorial),
                .middle(.root),
                .left(.sqrt),
                .middle(.exponent),
                .left(.negate),
                .middle(.divide),
                .middle(.multiply),
                .middle(.subtract),
                .middle(.add)]
    }
    
    func rawValue() -> String {
        switch self {
        case .left(let function):
            return function.rawValue
        case .middle(let function):
            return function.rawValue
        case .right(let function):
            return function.rawValue
        }
    }
}

enum Variable: String, CaseIterable {
    case answer = "ANS"
    case memory = "MEM"
}

enum Other: String, CaseIterable {
    case equal = "="
    case set = "SET"
    case alternate = "ALT"
    case delete = "DEL"
    case clear = "CLR"
}

enum Button: Equatable {
    case digit(Digit)
    case modifier(Modifier)
    case parenthesis(Parenthesis)
    case function(Function)
    case variable(Variable)
    case other(Other)
    
    
    // TDOD: This needs a unit test to ensure that all the types have been accounted for.
    static func from(rawValue: String) -> Button? {
        if let digit = Digit(rawValue: rawValue) {
            return .digit(digit)
        } else if let modifier = Modifier(rawValue: rawValue) {
            return .modifier(modifier)
        } else if let parenthesis = Parenthesis(rawValue: rawValue) {
            return .parenthesis(parenthesis)
        } else if let function = Function.from(rawValue: rawValue) {
            return .function(function)
        } else if let variable = Variable(rawValue: rawValue) {
            return .variable(variable)
        } else if let other = Other(rawValue: rawValue) {
            return .other(other)
        }
        
        return nil
    }
    
    func rawValue() -> String {
        switch self {
        case .digit(let button):
            return button.rawValue
        case .modifier(let button):
            return button.rawValue
        case .parenthesis(let button):
            return button.rawValue
        case .function(let button):
            return button.rawValue()
        case .variable(let button):
            return button.rawValue
        case .other(let button):
            return button.rawValue
        }
    }
}

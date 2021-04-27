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
    case abs = "~"
    case sum = "∑"
    
    var buttonDisplayValue: String {
        let value = self.rawValue
        
        switch self {
        case .abs:
            return "\(value)x"
        case .sum:
            return "\(value)i"
        case .negate, .sqrt:
            return value
        }
    }
}

enum Middle: String, CaseIterable {
    case add = "+"
    case subtract = "–"
    case modulo = "%"
    case multiply = "x"
    case divide = "÷"
    case exponent = "^"
    case root = "*√"
    
    var buttonDisplayValue: String {
        let value = self.rawValue
        
        switch self {
        case .exponent, .modulo:
            return "x\(value)y"
        case .add, .subtract, .multiply, .divide, .root:
            return value
        }
    }
}

enum Right: String, CaseIterable {
    case factorial = "!"
    
    var buttonDisplayValue: String {
        let value = self.rawValue
        
        switch self {
        case .factorial:
            return "i\(value)"
        }
    }
}

enum Function: Equatable {
    case left(Left)
    case middle(Middle)
    case right(Right)
    
    static var allCases: [Function] {
        var functions: [Function] = []
        
        functions += Left.allCases.map({ Function.left($0) })
        functions += Middle.allCases.map({ Function.middle($0) })
        functions += Right.allCases.map({ Function.right($0) })
        
        return functions
    }
    
    var buttonDisplayValue: String {
        switch self {
        case .left(let function):
            return function.buttonDisplayValue
        case .middle(let function):
            return function.buttonDisplayValue
        case .right(let function):
            return function.buttonDisplayValue
        }
    }
    
    // This is important, as 2^3^2 = 2^(3^2) and 2*√2*√10000 = √(√10000)
    // That's why we need to mark these functions as greedy, otherwise it would end up
    // like 2^3^2 = (2^3)^2 and 2*√2*√10000 = 1000^(1/√2), which is incorrect.
    var isGreedy: Bool {
        return [.middle(.exponent), .middle(.root)].contains(self)
    }
    
    /** Rank (from most important to least):
     *  0. abs, sum
     *  1. factorial
     *  2. exponent
     *  3. root
     *  4. sqrt
     *  5. negate, multiply, divide
     *  6. modulo
     *  7. add, subtract
     *  ∞. default level
     **/
    var rank: Int {
        switch self {
        case .left(let function):
            switch function {
            case .negate:
                return 5
            case .sqrt:
                return 4
            case .abs, .sum:
                return 0
            }
        case .middle(let function):
            switch function {
            case .add, .subtract:
                return 7
            case .modulo:
                return 6
            case .multiply, .divide:
                return 5
            case .root:
                return 3
            case .exponent:
                return 2
            }
        case .right(let function):
            switch function {
            case .factorial:
                return 1
            }
        }
    }
    
    var rawValue: String {
        switch self {
        case .left(let function):
            return function.rawValue
        case .middle(let function):
            return function.rawValue
        case .right(let function):
            return function.rawValue
        }
    }
    
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
}

enum Variable: String, CaseIterable {
    case answer = "ANS"
    case memory = "MEM"
}

enum Convenience: String, CaseIterable {
    case square = "x^2"
    case fraction = "1/x"
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
    case convenience(Convenience)
    case other(Other)
    
    static var allCases: [Button] {
        var buttons: [Button] = []
        
        buttons += Digit.allCases.map({ Button.digit($0) })
        buttons += Modifier.allCases.map({ Button.modifier($0) })
        buttons += Parenthesis.allCases.map({ Button.parenthesis($0) })
        buttons += Function.allCases.map({ Button.function($0) })
        buttons += Variable.allCases.map({ Button.variable($0) })
        buttons += Convenience.allCases.map({ Button.convenience($0) })
        buttons += Other.allCases.map({ Button.other($0) })
        
        return buttons
    }
    
    var buttonDisplayValue: String {
        switch self {
        case .function(let button):
            return button.buttonDisplayValue
        default:
            return self.rawValue
        }
    }
    
    var rawValue: String {
        switch self {
        case .digit(let button):
            return button.rawValue
        case .modifier(let button):
            return button.rawValue
        case .parenthesis(let button):
            return button.rawValue
        case .function(let button):
            return button.rawValue
        case .variable(let button):
            return button.rawValue
        case .convenience(let button):
            return button.rawValue
        case .other(let button):
            return button.rawValue
        }
    }
    
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
        } else if let convenience = Convenience(rawValue: rawValue) {
            return .convenience(convenience)
        } else if let other = Other(rawValue: rawValue) {
            return .other(other)
        }
        
        return nil
    }
}

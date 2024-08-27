//
//  String+Checks.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

extension String {
    func isProperDouble() -> Bool {
        guard let lastCharacter: Character = last else {
            return false
        }
        
        return isVariable() || isDouble() && lastCharacter != Character(Modifier.decimal.rawValue)
    }
    
    func isVariable() -> Bool {
        return Variable.allCases.map({$0.rawValue}).contains(self)
    }
    
    func isNumber() -> Bool {
        return !toMaxPrecisionNumber().isNaN
    }
    
    func isDouble() -> Bool {
        return Double(self) != nil
    }
    
    func isInteger() -> Bool {
        return hasSuffix(".0") || !contains(".") && toMaxPrecisionNumber().isWhole()
    }
    
    func isOpenParen() -> Bool {
        return self == Parenthesis.open.rawValue
    }
    
    func isCloseParen() -> Bool {
        return self == Parenthesis.close.rawValue
    }
    
    func toMaxPrecisionNumber() -> MaxPrecisionNumber {
        return MaxPrecisionNumber(self) ?? .nan
    }
}


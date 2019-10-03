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
        guard let lastCharacter: Character = self.last else {
            return false
        }
        
        return self.isVariable() || self.isDouble() && lastCharacter != Character(".")
    }
    
    func isVariable() -> Bool {
        return Variable.allCases.map({$0.rawValue}).contains(where: {$0 == self || "-" + $0 == self})
    }
    
    func isDouble() -> Bool {
        return Double(self) != nil
    }
    
    func isInt() -> Bool {
        return Int(self) != nil
    }
    
    func isOpenParen() -> Bool {
        return self == Parenthesis.open.rawValue
    }
    
    func isCloseParen() -> Bool {
        return self == Parenthesis.close.rawValue
    }
}


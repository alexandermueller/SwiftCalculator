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
        
        return self.isAFunction() || self.isDouble() && lastCharacter != Character(".")
    }
    
    func isAFunction() -> Bool {
        return [Button.memory.rawValue, Button.answer.rawValue].contains(where: {$0 == self || "-" + $0 == self})
    }
    
    func isDouble() -> Bool {
        return Double(self) != nil
    }
    
    func isInt() -> Bool {
        return Int(self) != nil
    }
    
    func isOpenParen() -> Bool {
        return self == Button.open.rawValue
    }
    
    func isCloseParen() -> Bool {
        return self == Button.close.rawValue
    }
}


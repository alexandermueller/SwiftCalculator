//
//  String+Helpers.swift
//  Calculator
//
//  Created by Alex Mueller on 2019-10-04.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

extension String {
    func countCharacters(_ characters: [Character], until stopCharacters: [Character] = []) -> Int {
        var count = 0
        
        for character in self {
            if stopCharacters.contains(character) {
                return count
            }
            
            count += characters.contains(character) ? 1 : 0
        }
        
        return count
    }
    
    func removeFirstContainedSuffix(_ suffixes: [String]) -> String {
        for suffix in suffixes {
            if self.hasSuffix(suffix) {
                return String(self.prefix(self.count - suffix.count))
            }
        }
        
        return self
    }
}

extension Array where Element: StringProtocol {
    func toExpressionString() -> String {
        var expressionString = ""
        
        for element in self {
            if let function = Function.from(rawValue: String(element)) {
                switch function {
                case .middle(.add), .middle(.subtract):
                    expressionString += " " + element + " "
                default:
                    expressionString += element
                }
                
                continue
            }
            
            expressionString += element
        }
        
        return expressionString
    }
}

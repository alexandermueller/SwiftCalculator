//
//  Array+ToExpressionString.swift
//  Calculator
//
//  Created by Alexander Mueller on 2020-06-01.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

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

//
//  ExpressionList.swift
//  Swift Calculator
//
//  Created by Alex Mueller on 2021-04-23.
//  Copyright © 2021 Alexander Mueller. All rights reserved.
//

import Foundation

typealias ExpressionList = [String]

extension ExpressionList {
    static var defaultList: ExpressionList { ["0"] }
    
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

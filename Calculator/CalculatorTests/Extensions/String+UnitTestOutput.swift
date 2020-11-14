//
//  String+ImplementsIsNaN.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension String : UnitTestOutput {
    func isNaN() -> Bool {
        return false
    }
    
    func isPositive() -> Bool {
        return false
    }
    
    static func |-| (lhs: String, rhs: String) -> String {
        return ""
    }
    
    static func <= (lhs: String, rhs: Double) -> Bool {
        return false
    }
}

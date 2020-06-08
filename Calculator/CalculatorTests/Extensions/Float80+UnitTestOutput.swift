//
//  Float80+isNaN.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension Float80 : UnitTestOutput {
    func isNaN() -> Bool {
        return self.isNaN
    }
    
    static func |-| (lhs: Float80, rhs: Float80) -> Float80 {
        return abs(lhs - rhs) / lhs
    }
    
    static func <= (lhs: Float80, rhs: Double) -> Bool {
        return lhs <= Float80(rhs)
    }
}

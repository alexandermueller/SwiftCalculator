//
//  MaxPrecisionNumber+Helpers.swift
//  Calculator
//
//  Created by Alexander Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension MaxPrecisionNumber {
    func isWhole() -> Bool {
        return self.remainder(dividingBy: 1) == 0 || self.isInfinite
    }
    
    func isEven() -> Bool {
        return self.truncatingRemainder(dividingBy: 2.0) == 0
    }
    
    func getSign() -> MaxPrecisionNumber {
        return self >= 0 ? 1.0 : -1.0
    }
}

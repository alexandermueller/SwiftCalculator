//
//  Double+Helpers.swift
//  Calculator
//
//  Created by Alexander Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension Double {
    func isWhole() -> Bool {
        return self.remainder(dividingBy: 1) == 0
    }
    
    func isEven() -> Bool {
        return self.truncatingRemainder(dividingBy: 2.0) == 0
    }
    
    func getSign() -> Double {
        return self >= 0 ? 1.0 : -1.0
    }
    
    func roundForPrecisionGreaterThanDisplay() -> Double {
         return roundForPrecisionGreaterThan(MaxDisplayLength.highestLimit.rawValue)
    }
    
    // TODO: This is very stopgappy... When the number is huge, the decimal shrinks and this stops working.
    //       either add a way to solve that issue, or do something else entirely!
    func roundForPrecisionGreaterThan(_ precision: Int) -> Double {
        let rounded = self.rounded(.toNearestOrAwayFromZero)
        let digits = String(self - rounded).count - 1
        
        return digits >= precision ? rounded : self
    }
}

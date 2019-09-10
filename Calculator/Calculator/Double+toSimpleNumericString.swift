//
//  Double+toSimpleNumericString.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-10.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import Foundation

extension Double {
    func toSimpleNumericString() -> String {
        if Double(Int(self)) == Double(self) {
            return String(Int(self))
        } else {
            return String(self)
        }
    }
}

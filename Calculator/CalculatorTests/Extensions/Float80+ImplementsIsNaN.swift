//
//  Float80+isNaN.swift
//  CalculatorTests
//
//  Created by Alex Mueller on 2020-05-31.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

extension Float80: ImplementsIsNaN {
    func isNaN() -> Bool {
        return self.isNaN
    }
}

//
//  MaxPrecisionNumber.swift
//  Calculator
//
//  Created by Alexander Mueller on 2020-11-24.
//  Copyright © 2020 Alexander Mueller. All rights reserved.
//

import Foundation

#if !os(Windows) && (arch(i386) || arch(x86_64))
    typealias MaxPrecisionNumber = Float80
#else
    typealias MaxPrecisionNumber = Double
#endif


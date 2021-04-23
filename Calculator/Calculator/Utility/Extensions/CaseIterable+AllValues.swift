//
//  CaseIterable+AllValues.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 2021-01-08.
//  Copyright © 2021 Alexander Mueller. All rights reserved.
//

import Foundation

extension CaseIterable where Self: RawRepresentable, Self.RawValue == String {
    static var allValues: [String] {
        return allCases.map({ $0.rawValue })
    }
}

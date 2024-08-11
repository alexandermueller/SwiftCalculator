//
//  Preferences.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 11.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation

@propertyWrapper
struct Preferences<T> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

//
//  Preferences.swift
//  Swift Calculator
//
//  Created by Alex Müller on 21.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

final class Preferences: ObservableObject {
    static var shared = Preferences()

    // User Experience
    @Published var hapticsEnabled = true
    @Published var reverseDisplayFields = false
    @Published var savedThemes: Set<Theme> = []
}


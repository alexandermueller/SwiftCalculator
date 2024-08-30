//
//  ColourTheme.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 30.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

enum Theme: String, CaseIterable {
    case auto
    case light
    case dark
    case custom

    var colourScheme: ColorScheme? {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        case .auto, .custom:
            nil
        }
    }
}

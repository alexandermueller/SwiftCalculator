//
//  ThemeType.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 04.09.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

enum ThemeType: CaseIterable, Equatable, Hashable, Codable {
    case auto
    case light
    case dark
    case custom(String?)

    static var allCases: [ThemeType] {
        [.auto, .light, .dark, .custom]
    }

    static var custom: ThemeType = .custom(nil)

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

    var isCustom: Bool {
        rawType == .custom
    }

    var rawType: ThemeType {
        switch self {
        case .light, .dark, .auto:
            self
        case .custom:
            .custom
        }
    }

    var rawValue: String {
        switch self {
        case .auto:
            "auto"
        case .light:
            "light"
        case .dark:
            "dark"
        case .custom:
            "custom"
        }
    }

    var name: String? {
        switch self {
        case .custom(let name):
            name
        default:
            nil
        }
    }
}

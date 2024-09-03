//
//  ColourTheme.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 30.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

enum ThemeType: CaseIterable, Equatable, Hashable {
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

final class Theme: ObservableObject {
    private struct Defaults {
        static let primaryColour = Color(light: .darkBrown, dark: .darkBrown)
        static let accentColour = Color(light: .orange, dark: .orange)
        static let viewSeparatorColour = Color(light: .black, dark: .white)
        static let buttonForegroundColour = Color(light: .white, dark: .white)
    }

    static var auto: Theme { Theme(type: .auto) }
    static var light: Theme { Theme(type: .light) }
    static var dark: Theme { Theme(type: .dark) }
    static var custom: Theme { Theme(type: .custom) }

    static var shared: Theme = .auto

    @Published var type: ThemeType {
        didSet {
            switch type {
            case .auto, .light, .dark:
                resetThemeColours()
            case .custom:
                break
            }
        }
    }

    // Text Field Colours
    @Published var textDisplayFieldForegroundColour: Color
    @Published var textDisplayFieldBackgroundColour: Color

    // Theme Colours
    @Published var primaryColour: Color
    @Published var accentColour: Color
    @Published var viewSeparatorColour: Color
    @Published var buttonForegroundColour: Color

    var copy: Theme {
        .init(
            type: type,
            textDisplayFieldForegroundColour: textDisplayFieldForegroundColour,
            textDisplayFieldBackgroundColour: textDisplayFieldBackgroundColour,
            primaryColour: primaryColour,
            accentColour: accentColour,
            viewSeparatorColour: viewSeparatorColour,
            buttonForegroundColour: buttonForegroundColour
        )

    }

    var name: String? {
        type.name
    }

    init(
        type: ThemeType,
        textDisplayFieldForegroundColour: Color = Constants.defaultTextColour,
        textDisplayFieldBackgroundColour: Color = Constants.defaultBackgroundColour,
        primaryColour: Color = Defaults.primaryColour,
        accentColour: Color = Defaults.accentColour,
        viewSeparatorColour: Color = Defaults.viewSeparatorColour,
        buttonForegroundColour: Color = Defaults.buttonForegroundColour
    ) {
        self.type = type
        self.textDisplayFieldForegroundColour = textDisplayFieldForegroundColour
        self.textDisplayFieldBackgroundColour = textDisplayFieldBackgroundColour
        self.primaryColour = primaryColour
        self.accentColour = accentColour
        self.viewSeparatorColour = viewSeparatorColour
        self.buttonForegroundColour = buttonForegroundColour
    }

    func load(_ theme: Theme) {
        self.type = theme.type
        self.textDisplayFieldForegroundColour = theme.textDisplayFieldForegroundColour
        self.textDisplayFieldBackgroundColour = theme.textDisplayFieldBackgroundColour
        self.primaryColour = theme.primaryColour
        self.accentColour = theme.accentColour
        self.viewSeparatorColour = theme.viewSeparatorColour
        self.buttonForegroundColour = theme.buttonForegroundColour
    }

    func resetThemeColours() {
        primaryColour = Defaults.primaryColour
        accentColour = Defaults.accentColour
        viewSeparatorColour = Defaults.viewSeparatorColour
        buttonForegroundColour = Defaults.buttonForegroundColour
        textDisplayFieldForegroundColour = Constants.defaultTextColour
        textDisplayFieldBackgroundColour = Constants.defaultBackgroundColour
    }
}

private extension Color {
    static var darkBrown: Color { .init(red: 0.6, green: 0.4, blue: 0.2) }
}

extension Theme: Equatable {
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        guard lhs.type.rawType == rhs.type.rawType else {
            return false
        }

        return switch (lhs.type, rhs.type) {
        case (.custom(let lhsName), .custom(let rhsName)):
            lhsName == rhsName &&
            lhs.textDisplayFieldForegroundColour == rhs.textDisplayFieldForegroundColour &&
            lhs.textDisplayFieldBackgroundColour == rhs.textDisplayFieldBackgroundColour &&
            lhs.primaryColour == rhs.primaryColour &&
            lhs.accentColour == rhs.accentColour &&
            lhs.viewSeparatorColour == rhs.viewSeparatorColour &&
            lhs.buttonForegroundColour == rhs.buttonForegroundColour
        default:
            true
        }
    }
}

extension Theme: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(textDisplayFieldForegroundColour)
        hasher.combine(textDisplayFieldBackgroundColour)
        hasher.combine(primaryColour)
        hasher.combine(accentColour)
        hasher.combine(viewSeparatorColour)
        hasher.combine(buttonForegroundColour)
    }
}

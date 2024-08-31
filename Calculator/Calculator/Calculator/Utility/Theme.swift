//
//  ColourTheme.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 30.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

enum ThemeType: String, CaseIterable {
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
            resetThemeColours()
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

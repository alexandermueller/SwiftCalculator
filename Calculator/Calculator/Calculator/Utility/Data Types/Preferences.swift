//
//  Preferences.swift
//  Swift Calculator
//
//  Created by Alex Müller on 21.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

final class Preferences: ObservableObject {
    private struct Defaults {
        // Theme Colours
        static let primaryColour = Color(light: .darkBrown, dark: .darkBrown)
        static let accentColour = Color(light: .orange, dark: .orange)
        static let viewSeparatorColour = Color(light: .black, dark: .white)
        static let buttonForegroundColour = Color(light: .white, dark: .white)
    }

    static var shared = Preferences()

    @Published var preferredColourScheme: ColorScheme? = nil
    @Published var reverseDisplayFields = false

    // Theme Colours
    @Published var primaryColour = Defaults.primaryColour
    @Published var accentColour = Defaults.accentColour
    @Published var viewSeparatorColour = Defaults.viewSeparatorColour
    @Published var buttonForegroundColour = Defaults.buttonForegroundColour

    // Text Field Colours
    @Published var textDisplayFieldForegroundColour = Constants.defaultTextColour
    @Published var textDisplayFieldBackgroundColour = Constants.defaultBackgroundColour

    func resetThemeColours() {
        primaryColour = Defaults.primaryColour
        accentColour = Defaults.accentColour
        viewSeparatorColour = Defaults.viewSeparatorColour
        buttonForegroundColour = Defaults.buttonForegroundColour
    }

    func resetTextFieldColours() {
        textDisplayFieldForegroundColour = Constants.defaultTextColour
        textDisplayFieldBackgroundColour = Constants.defaultBackgroundColour
    }
}

private extension Color {
    static var darkBrown: Color { .init(red: 0.6, green: 0.4, blue: 0.2) }
}

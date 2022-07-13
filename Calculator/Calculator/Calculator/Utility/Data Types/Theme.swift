//
//  Theme.swift
//  Swift Calculator
//
//  Created by Alex Müller on 21.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

final class Theme: ObservableObject {
    @Published var primaryColour = Color(light: Color(.brown), dark: Color(.brown))
    @Published var accentColour = Color(light: .orange, dark: .orange)
    @Published var textDisplayFieldForegroundColour = Color(light: .black, dark: .white)
    @Published var textDisplayFieldBackgroundColour = Color(light: .white, dark: .black)
    @Published var viewSeparatorColour = Color(light: .black, dark: .white)
    @Published var buttonForegroundColour = Color(light: .white, dark: .white)
    
    static var labelFontToHeightRatio: CGFloat = 0.33
    static var defaultAnimationDuration = 0.5
}

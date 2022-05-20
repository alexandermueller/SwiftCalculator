//
//  SwiftCalculatorApp.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-09.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
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
}

@main
struct SwiftCalculatorApp: App {
    @StateObject var currentTheme = Theme()
    
    var body: some Scene {
        WindowGroup {
            CalculatorView(viewModel: CalculatorViewModel(), theme: currentTheme)
        }
    }
}

//
//  SwiftCalculatorApp.swift
//  Calculator
//
//  Created by Alexander Mueller on 2019-09-09.
//  Copyright © 2019 Alexander Mueller. All rights reserved.
//

import SwiftUI

@main
struct SwiftCalculatorApp: App {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var preferences = Preferences.shared

    var body: some Scene {
        WindowGroup {
            CalculatorView(viewModel: CalculatorViewModel())
                .environmentObject(preferences)
                .preferredColorScheme(preferences.preferredColourScheme ?? colorScheme)
        }
    }
}

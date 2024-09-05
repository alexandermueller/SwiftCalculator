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
    @StateObject var preferences = Preferences.shared
    @StateObject var theme = Theme.shared
    @StateObject var viewModel = CalculatorViewModel()

    var body: some Scene {
        WindowGroup {
            CalculatorView(viewModel: viewModel)
                .environmentObject(preferences)
                .environmentObject(theme)
                .preferredColorScheme(theme.type.colourScheme)
                .task {
                    do {
                        try await preferences.load()
                        try await theme.load()
                    } catch {
                        fatalError(error.localizedDescription)
                    }
                }
        }
    }
}

//
//  SaveThemeSheetView.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 31.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

struct SaveThemeSheetView: View {
    @EnvironmentObject var preferences: Preferences
    @EnvironmentObject var theme: Theme

    @State private var themeName: String = ""

    var body: some View {
        Form {
            Section("New Theme") {
                TextField(
                    text: $themeName,
                    label: {
                        Text("Theme Name")
                    }
                )
            }

            SwiftUI.Button("Save Theme") {
                preferences.savedThemes[themeName] = theme
            }
        }
    }
}

struct SaveThemeSheetView_Preview: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.id) { colourScheme in
            SaveThemeSheetView()
                .preferredColorScheme(colourScheme)
                .environmentObject(Preferences())
                .environmentObject(Theme.custom)
        }
    }
}

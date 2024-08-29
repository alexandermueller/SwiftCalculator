//
//  SettingsMenuView.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 29.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import SwiftUI

struct SettingsMenuView: View {
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        VStack {
            List {
                Label(
                    title: { Text("Settings") },
                    icon: { Image(systemName: "gear") }
                )

                Toggle(
                    isOn: Binding(
                        get: { preferences.preferredColourScheme == .dark },
                        set: { preferences.preferredColourScheme = $0 ? .dark : nil }
                    )
                ) {
                    Text("Dark Mode")
                }
                
                Toggle(isOn: $preferences.reverseDisplayFields) {
                    Text("Reverse Text Display Fields")
                }

                Section("Theme Colours") {
                    ColorPicker(selection: $preferences.primaryColour) {
                        Text("Primary")
                    }

                    ColorPicker(selection: $preferences.accentColour) {
                        Text("Accent")
                    }

                    ColorPicker(selection: $preferences.viewSeparatorColour) {
                        Text("Separators")
                    }

                    ColorPicker(selection: $preferences.buttonForegroundColour) {
                        Text("Button Text")
                    }

                    SwiftUI.Button("Reset To Defaults") {
                        preferences.resetThemeColours()
                    }
                }

                Section("Text Field Colours") {
                    ColorPicker(selection: $preferences.textDisplayFieldForegroundColour) {
                        Text("Text")
                    }

                    ColorPicker(selection: $preferences.textDisplayFieldBackgroundColour) {
                        Text("Background")
                    }

                    SwiftUI.Button("Reset To Defaults") {
                        preferences.resetTextFieldColours()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsMenuView_Preview: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.id) { colourScheme in
            SettingsMenuView()
                .preferredColorScheme(colourScheme)
                .environmentObject(Preferences())
        }
    }
}

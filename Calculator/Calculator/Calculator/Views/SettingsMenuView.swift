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
        List {
            Label(
                title: {
                    Text("Settings")
                }, icon: {
                    Image(systemName: "gear")
                }
            )

            Section("General") {
                Toggle(isOn: $preferences.hapticsEnabled) {
                    Text("Enable Haptics")
                }

                Toggle(isOn: $preferences.reverseDisplayFields) {
                    Text("Flip Display Field Order")
                }

                Picker(selection: $preferences.theme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.rawValue.capitalized(with: .current)).tag(theme)
                    }
                } label: {
                    Text("Theme")
                }
            }

            if preferences.theme == .custom {
                Section("Theme Colours") {
                    ColorPicker(selection: $preferences.textDisplayFieldForegroundColour) {
                        Text("Display Text")
                    }

                    ColorPicker(selection: $preferences.textDisplayFieldBackgroundColour) {
                        Text("Display Background")
                    }

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
            }
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

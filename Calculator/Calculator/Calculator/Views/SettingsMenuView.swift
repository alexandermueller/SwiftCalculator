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
    @EnvironmentObject var theme: Theme

    @State private var showSaveThemeSheet = false
    @State private var showLoadThemeSheet = false
    @State private var showResetThemeAlert = false

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

                Picker(selection: $theme.type) {
                    ForEach(ThemeType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized(with: .current)).tag(type)
                    }
                } label: {
                    Text("Theme")
                }
            }

            if theme.type == .custom {
                Section("Theme Colours") {
                    ColorPicker(selection: $theme.textDisplayFieldForegroundColour) {
                        Text("Display Text")
                    }

                    ColorPicker(selection: $theme.textDisplayFieldBackgroundColour) {
                        Text("Display Background")
                    }

                    ColorPicker(selection: $theme.primaryColour) {
                        Text("Primary")
                    }

                    ColorPicker(selection: $theme.accentColour) {
                        Text("Accent")
                    }

                    ColorPicker(selection: $theme.viewSeparatorColour) {
                        Text("Separators")
                    }

                    ColorPicker(selection: $theme.buttonForegroundColour) {
                        Text("Button Text")
                    }
                }

                SwiftUI.Button("Save Theme") {
                    showSaveThemeSheet = true
                }
                .sheet(isPresented: $showSaveThemeSheet) {
                    SaveThemeSheetView()
                        .presentationDetents([.medium, .large])
                }


                SwiftUI.Button("Load Theme") {
                    showLoadThemeSheet = true
                }
                .sheet(isPresented: $showLoadThemeSheet) {
                    List {
                        ForEach(Array(preferences.savedThemes.enumerated()), id: \.offset) { (name, theme) in
                            
                        }
                    }
                    .presentationDetents([.medium, .large])
                }

                SwiftUI.Button("Reset To Default") {
                    showResetThemeAlert = true
                }
                .foregroundColor(.red)
                .alert(isPresented: $showResetThemeAlert) {
                    Alert(
                        title: Text("Are you sure?"),
                        primaryButton: .destructive(Text("Okay"), action: theme.resetThemeColours),
                        secondaryButton: .cancel()
                    )
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
                .environmentObject(Theme.custom)
        }
    }
}

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

    @State private var showLoadThemeSheet = false
    @State private var showResetThemeAlert = false
    @State private var showSaveConfirmation = false

    var pickedType: Binding<ThemeType> {
        .init(
            get: { theme.type.rawType },
            set: { theme.type = $0 }
        )
    }

    var saveThemeButtonIsDisabled: Bool {
        guard let name = theme.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return true
        }

        return preferences.savedThemes.first(with: name) == theme
    }

    var saveThemeButtonTitle: String {
        guard let name = theme.name, !name.isEmpty else {
            return "Create Theme"
        }

        return "\(preferences.savedThemes.containsName(name) ? "Update" : "Create") \(name.quoted)"
    }

    var themeName: Binding<String> {
        .init(
            get: { theme.name ?? "" },
            set: { name in
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                theme.type = .custom(trimmed.isEmpty ? nil : trimmed)
            }
        )
    }

    var themeSelection: Binding<Theme?> {
        .init(
            get: { theme },
            set: { newTheme in
                if let newTheme {
                    theme.load(newTheme)
                }
            }
        )
    }

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

                Picker(selection: pickedType) {
                    ForEach(ThemeType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized(with: .current)).tag(type)
                    }
                } label: {
                    Text("Theme")
                }
            }

            if theme.type.isCustom {
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

                TextField(
                    text: themeName,
                    prompt: Text("Input Custom Theme Name"),
                    label: {}
                )

                Section {
                    SwiftUI.Button(saveThemeButtonTitle) {
                        preferences.savedThemes.override(theme: theme)
                        showSaveConfirmation = true
                    }
                    .disabled(saveThemeButtonIsDisabled)
                    .alert(isPresented: $showSaveConfirmation) {
                        Alert(title: Text("\(theme.name?.quoted ?? "Theme") saved successfully"))
                    }

                    SwiftUI.Button("Load Saved Theme") {
                        showLoadThemeSheet = true
                    }
                    .disabled(preferences.savedThemes.isEmpty)
                    .sheet(isPresented: $showLoadThemeSheet) {
                        List(selection: themeSelection) {
                            ForEach(Array(preferences.getSavedThemes(sorted: true).enumerated()), id: \.offset) { _, theme in
                                if let name = theme.name {
                                    Text(name).tag(theme)
                                }
                            }
                        }
                        .presentationDetents([.height(200)])
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
                .environmentObject(Theme.custom)
        }
    }
}

private extension Set<Theme> {
    func containsName(_ name: String?) -> Bool {
        contains(where: { $0.type.name == name })
    }

    func first(with name: String?) -> Theme? {
        first(where: { $0.name == name })
    }

    mutating func override(theme: Theme) {
        guard let oldTheme = first(with: theme.name) else {
            insert(theme.copy)
            return
        }

        oldTheme.load(theme)
    }
}

private extension Preferences {
    func getSavedThemes(sorted: Bool) -> [Theme] {
        savedThemes.sorted(by: { $0.type.name ?? "" < $1.type.name ?? "" })
    }
}

private extension String {
    var quoted: String {
        self.isEmpty ? self : "\"\(self)\""
    }
}

//
//  SettingsMenuView.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 29.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import SwiftUI

struct SettingsMenuView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var theme: Theme

    @State private var showSecretMenu = false

    @State private var showLoadThemeSheet = false
    @State private var showResetThemeAlert = false
    @State private var showSaveConfirmation = false

    private var pickedType: Binding<ThemeType> {
        .init(
            get: { theme.type.rawType },
            set: { theme.type = $0 }
        )
    }

    private var saveThemeButtonIsDisabled: Bool {
        guard let name = theme.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            return true
        }

        return preferences.savedThemes.first(with: name) == theme
    }

    private var saveThemeButtonTitle: String {
        guard let name = theme.name, !name.isEmpty else {
            return "Create Theme"
        }

        return "\(preferences.savedThemes.containsName(name) ? "Update" : "Create") \(name.quoted)"
    }

    private var themeName: Binding<String> {
        .init(
            get: { theme.name ?? "" },
            set: { name in
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                theme.type = .custom(trimmed.isEmpty ? nil : trimmed)
            }
        )
    }

    private var themeSelection: Binding<Theme?> {
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
            .onTapGesture(count: 5) {
                showSecretMenu.toggle()
            }

            if showSecretMenu {
                Section("Secret") {
                    Toggle(isOn: $preferences.showDragOverlay) {
                        Text("Show Drag Overlay")
                    }
                }
            }

            Section("General") {
                Toggle(isOn: $preferences.hapticsEnabled.onChange(savePreferences)) {
                    Text("Enable Haptics")
                }

                Toggle(isOn: $preferences.reverseDisplayFields.onChange(savePreferences)) {
                    Text("Flip Display Field Order")
                }

                Picker(selection: pickedType.onChange(saveTheme)) {
                    ForEach(ThemeType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized(with: .current)).tag(type)
                    }
                } label: {
                    Text("Theme")
                }
            }

            if theme.type.isCustom {
                Section("Theme Colours") {
                    ColorPicker(selection: $theme.textDisplayFieldForegroundColour.onChange(saveTheme)) {
                        Text("Display Text")
                    }

                    ColorPicker(selection: $theme.textDisplayFieldBackgroundColour.onChange(saveTheme)) {
                        Text("Display Background")
                    }

                    ColorPicker(selection: $theme.primaryColour.onChange(saveTheme)) {
                        Text("Primary")
                    }

                    ColorPicker(selection: $theme.accentColour.onChange(saveTheme)) {
                        Text("Accent")
                    }

                    ColorPicker(selection: $theme.viewSeparatorColour.onChange(saveTheme)) {
                        Text("Separators")
                    }

                    ColorPicker(selection: $theme.buttonForegroundColour.onChange(saveTheme)) {
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
                    text: themeName.onChange(saveTheme),
                    prompt: Text("Input Custom Theme Name"),
                    label: {}
                )

                Section {
                    SwiftUI.Button(saveThemeButtonTitle) {
                        preferences.savedThemes.override(theme: theme)
                        savePreferences()
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
                        List(selection: themeSelection.onChange(saveTheme)) {
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

    private func saveAction<T: Singleton & Storable>(on objectType: T.Type) {
        Task {
            do {
                try await T.shared.save()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    private func savePreferences() {
        saveAction(on: Preferences.self)
    }

    private func saveTheme() {
        saveAction(on: Theme.self)
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

@MainActor
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

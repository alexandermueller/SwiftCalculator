//
//  ColourTheme.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 30.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class Theme: ObservableObject, Codable, Singleton {
    private struct Defaults {
        static let primaryColour = Color(light: .darkBrown, dark: .darkBrown)
        static let accentColour = Color(light: .orange, dark: .orange)
        static let viewSeparatorColour = Color(light: .black, dark: .white)
        static let buttonForegroundColour = Color(light: .white, dark: .white)
    }

    static var auto: Theme { Theme(type: .auto) }
    static var light: Theme { Theme(type: .light) }
    static var dark: Theme { Theme(type: .dark) }
    static var custom: Theme { Theme(type: .custom) }

    static var shared: Theme = .auto

    @Published var type: ThemeType {
        didSet {
            switch type {
            case .auto, .light, .dark:
                resetThemeColours()
            case .custom:
                break
            }
        }
    }

    // Text Field Colours
    @Published var textDisplayFieldForegroundColour: Color
    @Published var textDisplayFieldBackgroundColour: Color

    // Theme Colours
    @Published var primaryColour: Color
    @Published var accentColour: Color
    @Published var viewSeparatorColour: Color
    @Published var buttonForegroundColour: Color

    var copy: Theme {
        .init(
            type: type,
            textDisplayFieldForegroundColour: textDisplayFieldForegroundColour,
            textDisplayFieldBackgroundColour: textDisplayFieldBackgroundColour,
            primaryColour: primaryColour,
            accentColour: accentColour,
            viewSeparatorColour: viewSeparatorColour,
            buttonForegroundColour: buttonForegroundColour
        )

    }

    var name: String? {
        type.name
    }

    init(
        type: ThemeType,
        textDisplayFieldForegroundColour: Color = Constants.defaultTextColour,
        textDisplayFieldBackgroundColour: Color = Constants.defaultBackgroundColour,
        primaryColour: Color = Defaults.primaryColour,
        accentColour: Color = Defaults.accentColour,
        viewSeparatorColour: Color = Defaults.viewSeparatorColour,
        buttonForegroundColour: Color = Defaults.buttonForegroundColour
    ) {
        self.type = type
        self.textDisplayFieldForegroundColour = textDisplayFieldForegroundColour
        self.textDisplayFieldBackgroundColour = textDisplayFieldBackgroundColour
        self.primaryColour = primaryColour
        self.accentColour = accentColour
        self.viewSeparatorColour = viewSeparatorColour
        self.buttonForegroundColour = buttonForegroundColour
    }

    func load(_ theme: Theme) {
        self.type = theme.type

        if theme.type.isCustom {
            self.textDisplayFieldForegroundColour = theme.textDisplayFieldForegroundColour
            self.textDisplayFieldBackgroundColour = theme.textDisplayFieldBackgroundColour
            self.primaryColour = theme.primaryColour
            self.accentColour = theme.accentColour
            self.viewSeparatorColour = theme.viewSeparatorColour
            self.buttonForegroundColour = theme.buttonForegroundColour
        }
    }

    func resetThemeColours() {
        primaryColour = Defaults.primaryColour
        accentColour = Defaults.accentColour
        viewSeparatorColour = Defaults.viewSeparatorColour
        buttonForegroundColour = Defaults.buttonForegroundColour
        textDisplayFieldForegroundColour = Constants.defaultTextColour
        textDisplayFieldBackgroundColour = Constants.defaultBackgroundColour
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case type
        case textDisplayFieldForegroundColour
        case textDisplayFieldBackgroundColour
        case primaryColour
        case accentColour
        case viewSeparatorColour
        case buttonForegroundColour
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(ThemeType.self, forKey: .type)
        textDisplayFieldForegroundColour = try container.decodeResolvedColor(forKey: .textDisplayFieldForegroundColour)
        textDisplayFieldBackgroundColour = try container.decodeResolvedColor(forKey: .textDisplayFieldBackgroundColour)
        primaryColour = try container.decodeResolvedColor(forKey: .primaryColour)
        accentColour = try container.decodeResolvedColor(forKey: .accentColour)
        viewSeparatorColour = try container.decodeResolvedColor(forKey: .viewSeparatorColour)
        buttonForegroundColour = try container.decodeResolvedColor(forKey: .buttonForegroundColour)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type, forKey: .type)
        try container.encode(textDisplayFieldForegroundColour.resolved, forKey: .textDisplayFieldForegroundColour)
        try container.encode(textDisplayFieldBackgroundColour.resolved, forKey: .textDisplayFieldBackgroundColour)
        try container.encode(primaryColour.resolved, forKey: .primaryColour)
        try container.encode(accentColour.resolved, forKey: .accentColour)
        try container.encode(viewSeparatorColour.resolved, forKey: .viewSeparatorColour)
        try container.encode(buttonForegroundColour.resolved, forKey: .buttonForegroundColour)
    }
}

private extension Color {
    static var darkBrown: Color { .init(red: 0.6, green: 0.4, blue: 0.2) }

    var resolved: Resolved {
        resolve(in: .init())
    }
}

private extension KeyedDecodingContainer {
    func decodeResolvedColor(forKey key: KeyedDecodingContainer<K>.Key) throws -> Color {
        Color(try decode(Color.Resolved.self, forKey: key))
    }
}

// MARK: - Equatable
extension Theme: Equatable {
    static func == (lhs: Theme, rhs: Theme) -> Bool {
        guard lhs.type.rawType == rhs.type.rawType else {
            return false
        }

        return switch (lhs.type, rhs.type) {
        case (.custom(let lhsName), .custom(let rhsName)):
            lhsName == rhsName &&
            lhs.textDisplayFieldForegroundColour == rhs.textDisplayFieldForegroundColour &&
            lhs.textDisplayFieldBackgroundColour == rhs.textDisplayFieldBackgroundColour &&
            lhs.primaryColour == rhs.primaryColour &&
            lhs.accentColour == rhs.accentColour &&
            lhs.viewSeparatorColour == rhs.viewSeparatorColour &&
            lhs.buttonForegroundColour == rhs.buttonForegroundColour
        default:
            true
        }
    }
}

// MARK: - Hashable
extension Theme: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(textDisplayFieldForegroundColour)
        hasher.combine(textDisplayFieldBackgroundColour)
        hasher.combine(primaryColour)
        hasher.combine(accentColour)
        hasher.combine(viewSeparatorColour)
        hasher.combine(buttonForegroundColour)
    }
}

// MARK: - Storable
extension Theme: Storable {
    static func fileURL() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appendingPathComponent(Constants.themeFileName)
    }

    func load() async throws {
        let task = Task<Theme, Error> {
            let fileURL = try Self.fileURL()
            
            guard let data = try? Data(contentsOf: fileURL) else {
                FileManager().createFile(atPath: fileURL.absoluteString, contents: nil)
                return Theme.shared
            }
            
            return try JSONDecoder().decode(Theme.self, from: data)
        }
        
        load(try await task.value)
    }

    func save() async throws {
        let task = Task {
            let data = try JSONEncoder().encode(self)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }

        _ = try await task.value
    }
}

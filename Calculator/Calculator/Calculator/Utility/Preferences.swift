//
//  Preferences.swift
//  Swift Calculator
//
//  Created by Alex Müller on 21.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

@MainActor
final class Preferences: ObservableObject, Codable, Singleton {
    static var shared = Preferences()

    // User Experience
    @Published var hapticsEnabled = true
    @Published var reverseDisplayFields = false
    @Published var savedThemes: Set<Theme> = []

    init() {}

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case hapticsEnabled
        case reverseDisplayFields
        case savedThemes
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hapticsEnabled = try container.decode(Bool.self, forKey: .hapticsEnabled)
        reverseDisplayFields = try container.decode(Bool.self, forKey: .reverseDisplayFields)
        savedThemes = try container.decode(Set<Theme>.self, forKey: .savedThemes)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(reverseDisplayFields, forKey: .reverseDisplayFields)
        try container.encode(savedThemes, forKey: .savedThemes)
    }
}

extension Preferences: Equatable {
    static func == (lhs: Preferences, rhs: Preferences) -> Bool {
        lhs.hapticsEnabled == rhs.hapticsEnabled &&
        lhs.reverseDisplayFields == rhs.reverseDisplayFields &&
        lhs.savedThemes == rhs.savedThemes
    }
}

extension Preferences: Storable {
    static func fileURL() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appendingPathComponent(Constants.preferencesFileName)
    }

    func load() async throws {
        let task = Task<Preferences, Error> {
            let fileURL = try Self.fileURL()

            guard let data = try? Data(contentsOf: fileURL) else {
                FileManager().createFile(atPath: fileURL.absoluteString, contents: nil)
                return Preferences.shared
            }

            return try JSONDecoder().decode(Preferences.self, from: data)
        }

        let preferences = try await task.value
        self.hapticsEnabled = preferences.hapticsEnabled
        self.reverseDisplayFields = preferences.reverseDisplayFields
        self.savedThemes = preferences.savedThemes
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


//
//  File.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 05.09.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation

protocol Storable {
    static func fileURL() throws -> URL

    func load() async throws
    func save() async throws
}

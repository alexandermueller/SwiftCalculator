//
//  Font+SystemForGeometry.swift
//  Swift Calculator
//
//  Created by Alex Müller on 18.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

extension Font {
    static func system(for geometry: GeometryProxy, scale: Double = 1, bold: Bool = false) -> Font {
        let font: Font = .system(size: geometry.size.height * Theme.labelFontToHeightRatio * scale)

        if bold {
            return font.bold()
        }

        return font
    }
}

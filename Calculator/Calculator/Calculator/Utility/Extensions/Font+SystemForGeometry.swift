//
//  Font+SystemForGeometry.swift
//  Swift Calculator
//
//  Created by Alex Müller on 18.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

extension Font {
    static func system(for geometry: GeometryProxy) -> Font {
        .system(size: geometry.size.height * Theme.labelFontToHeightRatio)
    }
}

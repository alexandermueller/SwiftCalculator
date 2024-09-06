//
//  TouchOverlay.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 06.09.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

struct TouchOverlay: ViewModifier {
    @State private var touchLocation: CGPoint? = nil

    func body(content: Content) -> some View {
        content
            .overlay {
                if let touchLocation {
                    Circle()
                        .fill(Constants.defaultTextColour)
                        .frame(width: 55)
                        .opacity(0.55)
                        .position(touchLocation)
                }
            }
            .onTouchDownGesture { location in
                touchLocation = location
            }
    }
}

extension View {
    func touchOverlay() -> some View {
        modifier(TouchOverlay())
    }
}



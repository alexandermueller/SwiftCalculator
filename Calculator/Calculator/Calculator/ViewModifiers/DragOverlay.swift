//
//  TouchOverlay.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 06.09.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

private struct DragOverlay: ViewModifier {
    @State private var touchLocation: CGPoint? = nil

    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if let touchLocation, isEnabled {
                    Circle()
                        .fill(Constants.defaultTextColour)
                        .frame(width: 55)
                        .opacity(0.55)
                        .position(touchLocation)
                }
            }
            .onTouchDownGesture(minimumDistance: 1) { location in
                touchLocation = location
            }
    }
}

extension View {
    func dragOverlay(isEnabled: Bool = false) -> some View {
        modifier(DragOverlay(isEnabled: isEnabled))
    }
}



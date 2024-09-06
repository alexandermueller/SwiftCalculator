//
//  View+OnTouchDownGesture.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 06.09.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import Foundation
import SwiftUI

private struct OnTouchDownGestureModifier: ViewModifier {
    let callback: (CGPoint?) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { gesture in
                        self.callback(gesture.location)
                    }
                    .onEnded { gesture in
                        self.callback(nil)
                    }
            )
    }
}

extension View {
    func onTouchDownGesture(callback: @escaping (CGPoint?) -> Void) -> some View {
        modifier(OnTouchDownGestureModifier(callback: callback))
    }
}

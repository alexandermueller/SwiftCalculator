//
//  ButtonView.swift
//  Swift Calculator
//
//  Created by Alex Müller on 18.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

struct ButtonView: View {
    @EnvironmentObject var theme: Theme
    @State var isPressing = false
    @State var animation: Animation? = nil
    
    let button: Button
    let isToggled: Bool
    let tap: () -> Void
    let longPress: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(isPressing ? theme.accentColour : theme.primaryColour)
                .animation(nil)
                .mask(Circle().frame(width: diameter(for: geometry), height: diameter(for: geometry), alignment: .center))
                .animation(animation)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onTapGesture {
                    tap()
                }
                .onLongPressGesture(minimumDuration: button.hasLongPressMapping ? 0 : .infinity) {
                    Haptics.shared.play(.heavy)
                    longPress()
                } onPressingChanged: { isPressing in
                    self.isPressing = isPressing
                    self.animation = nil
                    
                    if isPressing {
                        if button.hasLongPressMapping {
                            Haptics.shared.play(.rigid)
                            animation = Animation.easeInOut(duration: Theme.defaultAnimationDuration)
                        } else {
                            Haptics.shared.play(.heavy)
                        }
                    }
                }
            Text(button.rawValue)
                .foregroundColor(isPressing || !isToggled ? theme.buttonForegroundColour : theme.accentColour)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipped()
    }
    
    func diameter(for geometry: GeometryProxy) -> CGFloat {
        isPressing && button.hasLongPressMapping ? smallestRadius(for: geometry.size) : largestRadius(for: geometry.size)
    }
    
    func smallestRadius(for bounds: CGSize) -> CGFloat {
        min(bounds.width, bounds.height) * 0.75
    }
    
    func largestRadius(for bounds: CGSize) -> CGFloat {
        max(bounds.width, bounds.height) * 1.25
    }
}

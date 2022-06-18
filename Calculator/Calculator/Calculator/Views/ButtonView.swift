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
    @GestureState var isPressing = false

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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .gesture( // TODO: liftup after a long press on a button without a long press mapping should act like a tap
                    LongPressGesture(minimumDuration: button.hasLongPressMapping ? Theme.defaultAnimationDuration : .infinity)
                        .updating($isPressing) { currentState, gestureState, transaction in
                            gestureState = currentState
                            
                            if button.hasLongPressMapping {
                                Haptics.shared.play(.rigid)
                                transaction.animation = Animation.easeInOut(duration: Theme.defaultAnimationDuration)
                            } else {
                                Haptics.shared.play(.heavy)
                            }
                        }
                        .onEnded { _ in
                            Haptics.shared.play(.heavy)
                            longPress()
                        }
                )
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            tap()
                        }
                )
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

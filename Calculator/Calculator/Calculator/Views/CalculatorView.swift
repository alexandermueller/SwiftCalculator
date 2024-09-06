//
//  CalculatorView.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 29.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var theme: Theme
    @ObservedObject var viewModel: CalculatorViewModel

    @State private var verticalDragOffset: CGFloat = 0
    @State private var settingsMenuIsOpen = false {
        didSet {
            if !settingsMenuIsOpen {
                verticalDragOffset = 0
            }
        }
    }

    private let toggleSettingsThreshold = 0.30
    private let minimumInterfaceHeightRatio = 0.53

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: Constants.viewSeparatorHeight) {
                InterfaceView(viewModel: viewModel)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                verticalDragOffset = -value.translation.height
                            }
                            .onEnded { value in
                                if settingsMenuIsOpen, -verticalDragOffset > toggleThreshold(for: geometry) {
                                    settingsMenuIsOpen = false
                                    return
                                }

                                if !settingsMenuIsOpen, verticalDragOffset > toggleThreshold(for: geometry) {
                                    settingsMenuIsOpen = true
                                }

                                verticalDragOffset = 0
                            }
                    )
                    .frame(minHeight: geometry.size.height * minimumInterfaceHeightRatio)
                    .touchOverlay()

                if settingsMenuIsOpen || verticalDragOffset > 0 {
                    SettingsMenuView()
                        .frame(maxHeight: max(settingsMenuIsOpen ? maxSettingsHeight(for: geometry) + verticalDragOffset : verticalDragOffset, 0))
                }
            }
            .background(theme.viewSeparatorColour)
        }
    }

    private func maxSettingsHeight(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height * (1 - minimumInterfaceHeightRatio)
    }

    private func toggleThreshold(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height * minimumInterfaceHeightRatio * toggleSettingsThreshold
    }
}

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.id) { colourScheme in
            CalculatorView(viewModel: CalculatorViewModel())
                .preferredColorScheme(colourScheme)
                .environmentObject(Preferences())
                .environmentObject(Theme.auto)
        }
    }
}


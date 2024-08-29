//
//  CalculatorView.swift
//  Swift Calculator
//
//  Created by Alexander Mueller on 29.08.24.
//  Copyright © 2024 Alexander Mueller. All rights reserved.
//

import SwiftUI

struct CalculatorView: View {
    @ObservedObject var viewModel: CalculatorViewModel

    @State private var settingsIsOpen = false
    @State private var settingsHeight: CGFloat = 0
    @State private var dragOffset: CGFloat = 0 {
        didSet {
            settingsHeight += dragOffset
        }
    }

    private let showSettingsThreshold = 0.75
    private let minimumInterfaceHeightRatio = 0.53

    var body: some View {
        GeometryReader { geometry in
            VStack {
                InterfaceView(viewModel: viewModel)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = -value.translation.height
                            }
                            .onEnded { value in
                                if settingsHeight > showThreshold(for: geometry) {
                                    settingsIsOpen = true
                                    
                                    withAnimation {
                                        settingsHeight = maxSettingsHeight(for: geometry)
                                    }
                                } else {
                                    settingsIsOpen = false
                                    
                                    withAnimation {
                                         settingsHeight = .zero
                                    }
                                }
                            }
                    )
                    .frame(minHeight: geometry.size.height * minimumInterfaceHeightRatio)

                if settingsHeight > 0 {
                    SettingsMenuView()
                        .frame(height: settingsHeight)
                }
            }
        }
    }

    func maxSettingsHeight(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height * (1 - minimumInterfaceHeightRatio)
    }

    func showThreshold(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height * minimumInterfaceHeightRatio * showSettingsThreshold
    }
}

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.id) { colourScheme in
            CalculatorView(viewModel: CalculatorViewModel())
                .preferredColorScheme(colourScheme)
                .environmentObject(Preferences())
        }
    }
}


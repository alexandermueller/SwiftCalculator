//
//  InterfaceView.swift
//  Swift Calculator
//
//  Created by Alex Müller on 16.05.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

fileprivate enum DisplayFieldType: CaseIterable {
    case input
    case output
}

struct InterfaceView: View {
    @EnvironmentObject var preferences: Preferences
    @ObservedObject var viewModel: CalculatorViewModel

    private let aspectRatioThreshold: CGFloat = 0.75

    private var displayFieldTypes: [DisplayFieldType] {
        preferences.reverseDisplayFields ? DisplayFieldType.allCases.reversed() : DisplayFieldType.allCases
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 2) {
                VStack(spacing: 2) {
                    ForEach(Array(displayFieldTypes.enumerated()), id: \.offset) { _, displayFieldType in
                        switch displayFieldType {
                        case .input:
                            inputDisplayField(for: geometry)
                        case .output:
                            outputDisplayField(for: geometry)
                        }
                    }
                }
                VStack(spacing: 0) {
                    VariableDisplayView(variableValueDict: viewModel.variableValueDict)
                        .frame(height: buttonViewHeight(for: geometry))
                        .foregroundColor(preferences.accentColour)
                    ButtonDisplayView(viewModel: viewModel)
                        .frame(height: buttonDisplayViewHeight(for: geometry))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.01)
            .background(preferences.viewSeparatorColour)
        }
        .ignoresSafeArea()
    }

    private func arithmeticExpressionTextDisplayFieldHeight(for geometry: GeometryProxy) -> CGFloat {
        buttonViewHeight(for: geometry) * 1.5
    }

    private func buttonDisplayViewHeight(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height / 2.0
    }

    private func buttonViewHeight(for geometry: GeometryProxy) -> CGFloat {
        buttonDisplayViewHeight(for: geometry) / CGFloat(ButtonLayout.fullButtonsLayout.count)
    }

    @ViewBuilder private func inputDisplayField(for geometry: GeometryProxy) -> some View {
        TextDisplayField(text: viewModel.expressionText + "=", hint: viewModel.textDisplayHint)
            .frame(height: arithmeticExpressionTextDisplayFieldHeight(for: geometry))
            .foregroundColor(viewModel.textDisplayColour.wrappedValue)
    }

    @ViewBuilder private func outputDisplayField(for geometry: GeometryProxy) -> some View {
        TextDisplayField(text: viewModel.displayedValue.toSimpleNumericString(for: .fullDisplay))
            .foregroundColor(preferences.primaryColour)
    }
}

extension ColorScheme: Identifiable {
    public var id: Self { self }
}

struct InterfaceView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.id) { colourScheme in
            InterfaceView(viewModel: CalculatorViewModel())
                .preferredColorScheme(colourScheme)
                .environmentObject(Preferences())
        }
    }
}

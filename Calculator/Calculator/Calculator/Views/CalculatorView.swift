//
//  CalculatorView.swift
//  Swift Calculator
//
//  Created by Alex Müller on 16.05.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

struct CalculatorView: View {
    @ObservedObject var viewModel: CalculatorViewModel
    @ObservedObject var theme: Theme
    
    let aspectRatioThreshold: CGFloat = 0.75
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 2) {
                TextDisplayField(text: viewModel.expressionText + "=")
                    .frame(height: arithmeticExpressionTextDisplayFieldHeight(for: geometry))
                    .foregroundColor(viewModel.textDisplayColour)
                TextDisplayField(text: viewModel.displayedValue.toSimpleNumericString(for: .fullDisplay))
                    .foregroundColor(theme.primaryColour)
                VStack(spacing: 0) {
                    VariableDisplayView(variableValueDict: viewModel.variableValueDict)
                        .frame(height: buttonViewHeight(for: geometry))
                        .foregroundColor(theme.accentColour)
                    ButtonDisplayView(viewModel: viewModel)
                        .frame(height: buttonDisplayViewHeight(for: geometry))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.01)
            .background(theme.viewSeparatorColour)
        }
        .ignoresSafeArea()
        .environmentObject(theme)
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
}

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorView(viewModel: CalculatorViewModel(), theme: Theme())
            .preferredColorScheme(.dark)
        CalculatorView(viewModel: CalculatorViewModel(), theme: Theme())
            .preferredColorScheme(.light)
    }
}

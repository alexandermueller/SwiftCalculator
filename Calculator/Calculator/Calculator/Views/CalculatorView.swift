//
//  CalculatorView.swift
//  Swift Calculator
//
//  Created by Alex Müller on 16.05.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

typealias ButtonLayout = [[Button]]
typealias VariableValuePair = (variable: Variable, value: MaxPrecisionNumber)

struct TextDisplayField: View {
    @EnvironmentObject var theme: Theme
    
    let text: String
    
    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .font(.system(for: geometry))
                .multilineTextAlignment(.trailing)
        }
        .background(theme.textDisplayFieldBackgroundColour)
    }
}

struct VariableDisplayView: View {
    @EnvironmentObject var theme: Theme

    let variableValueDict: VariableValueDict
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(variableValueDict.sortedKeyValuePairArray, id:\.variable.rawValue) { (variable, value) in
                    Text(variable.rawValue)
                    Text("= \(value.toSimpleNumericString(for: .buttonDisplay)) ")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.primaryColour)
                .font(.system(for: geometry))
            }
        }
    }
}

struct Pressed: ButtonStyle {
    let theme: Theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? theme.accentColour : theme.primaryColour)
            .animation(nil)
    }
}

struct ButtonView: View {
    @EnvironmentObject var theme: Theme
    
    let button: Button
    let action: () -> Void
    
    var body: some View {
        SwiftUI.Button(action: action) {
            Text(button.rawValue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(Pressed(theme: theme))
    }
}

struct ButtonDisplayView: View {
    enum Mode {
        case normal
        case alternate
    }
    
    @EnvironmentObject var theme: Theme
    @ObservedObject var viewModel: CalculatorViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Button.layout(for: viewModel.buttonDisplayViewMode), id:\.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { button in
                        GeometryReader { geometry in
                            ButtonView(button: button) {
                                viewModel.buttonPressed = button
                            }
                            .font(.system(for: geometry))
                            .foregroundColor(viewModel.buttonDisplayViewMode == .alternate && button == .other(.alternate) ? theme.accentColour : theme.buttonForegroundColour)
                        }
                    }
                }
            }
        }
    }
}

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
            .environmentObject(theme)
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
}

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorView(viewModel: CalculatorViewModel(), theme: Theme())
            .preferredColorScheme(.dark)
        CalculatorView(viewModel: CalculatorViewModel(), theme: Theme())
            .preferredColorScheme(.light)
    }
}

private extension Button {
    static func layout(for buttonDisplayViewMode: ButtonDisplayView.Mode) -> ButtonLayout {
        switch buttonDisplayViewMode {
        case .normal:
            return .normalButtonsLayout
        case .alternate:
            return .alternateButtonsLayout
        }
    }
}

private extension ButtonLayout {
    static var normalButtonsLayout: ButtonLayout {
        [[  .other(.alternate),   .variable(.answer),      .variable(.memory),               .other(.delete) ],
         [ .parenthesis(.open), .parenthesis(.close), .function(.left(.sqrt)), .function(.middle(.exponent)) ],
         [      .digit(.seven),       .digit(.eight),           .digit(.nine),   .function(.middle(.divide)) ],
         [       .digit(.four),        .digit(.five),            .digit(.six), .function(.middle(.multiply)) ],
         [        .digit(.one),         .digit(.two),          .digit(.three), .function(.middle(.subtract)) ],
         [       .digit(.zero),  .modifier(.decimal),          .other(.equal),      .function(.middle(.add)) ]]
    }
    
    static var alternateButtonsLayout: ButtonLayout {
        [[  .other(.alternate),   .variable(.answer),      .variable(.memory),               .other(.delete) ],
         [ .parenthesis(.open), .parenthesis(.close), .convenience(.fraction),         .convenience(.square) ],
         [      .digit(.seven),       .digit(.eight),           .digit(.nine),   .function(.middle(.modulo)) ],
         [       .digit(.four),        .digit(.five),            .digit(.six), .function(.right(.factorial)) ],
         [        .digit(.one),         .digit(.two),          .digit(.three),        .function(.left(.abs)) ],
         [       .digit(.zero),  .modifier(.decimal),            .other(.set),        .function(.left(.sum)) ]]
    }
    
    static var fullButtonsLayout: ButtonLayout {
        [[  .variable(.answer),   .variable(.memory),            .other(.set),               .other(.delete),       .convenience(.fraction) ],
         [ .parenthesis(.open), .parenthesis(.close), .function(.left(.sqrt)), .function(.middle(.exponent)),         .convenience(.square) ],
         [      .digit(.seven),       .digit(.eight),           .digit(.nine),   .function(.middle(.divide)),   .function(.middle(.modulo)) ],
         [       .digit(.four),        .digit(.five),            .digit(.six), .function(.middle(.multiply)), .function(.right(.factorial)) ],
         [        .digit(.one),         .digit(.two),          .digit(.three), .function(.middle(.subtract)),        .function(.left(.abs)) ],
         [       .digit(.zero),  .modifier(.decimal),          .other(.equal),      .function(.middle(.add)),        .function(.left(.sum)) ]]
    }
}

extension VariableValueDict {
    var sortedKeyValuePairArray: [VariableValuePair] {
        Variable.allCases.map { ($0, self[$0, default: 0]) }
    }
}

private extension Font {
    static func system(for geometry: GeometryProxy) -> Font {
        .system(size: geometry.size.height * Theme.labelFontToHeightRatio)
    }
}

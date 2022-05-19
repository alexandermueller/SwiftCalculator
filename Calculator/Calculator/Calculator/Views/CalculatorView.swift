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
    enum DisplayFieldSize {
        case large
        case medium
        case small
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    let text: String
    let size: DisplayFieldSize
    
    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(Color(colorScheme == .light ? .white : .black))
    }
}

struct VariableDisplayView: View {
    let variableValueDict: VariableValueDict
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(variableValueDict.sortedKeyValuePairArray, id:\.variable.rawValue) { (variable, value) in
                Text(variable.rawValue)
                Text("= \(value.toSimpleNumericString(for: .buttonDisplay)) ")
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.orange)
        }
        .background(Color(.brown))
    }
}

struct Pressed: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color(configuration.isPressed ? .orange : .brown))
            .animation(nil)
    }
}

struct ButtonView: View {
    let button: Button
    let action: () -> Void
    
    var body: some View {
        SwiftUI.Button(action: action) {
            Text(button.rawValue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(Pressed())
    }
}

struct ButtonDisplayView: View {
    enum Mode {
        case normal
        case alternate
    }
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: CalculatorViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Button.layout(for: viewModel.buttonDisplayViewMode), id:\.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { button in
                        ButtonView(button: button) {
                            viewModel.buttonPressed = button
                        }
                        .foregroundColor(viewModel.buttonDisplayViewMode == .alternate && button == .other(.alternate) ? .orange : .white)
                    }
                }
            }
        }
    }
}

struct CalculatorView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject fileprivate var viewModel: CalculatorViewModel
    
    let viewMargin: CGFloat = 2
    let labelFontToHeightRatio: CGFloat = 0.33
    let aspectRatioThreshold: CGFloat = 0.75
    
    var body: some View {
        VStack(spacing: kViewMargin) {
            TextDisplayField(text: viewModel.expressionText + "=", size: .small)
            TextDisplayField(text: viewModel.currentValue.toSimpleNumericString(for: .fullDisplay), size: .large)
            
            VStack(spacing: 0) {
                VariableDisplayView(variableValueDict: viewModel.variableValueDict)
                ButtonDisplayView(viewModel: viewModel)
            }
        }
        .background(Color(colorScheme == .light ? .black : .white))
    }
}

struct CalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        CalculatorView(viewModel: CalculatorViewModel())
            .preferredColorScheme(.dark)
        CalculatorView(viewModel: CalculatorViewModel())
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

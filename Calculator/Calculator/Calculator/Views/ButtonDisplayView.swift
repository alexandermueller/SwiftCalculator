//
//  ButtonDisplayView.swift
//  Swift Calculator
//
//  Created by Alex Müller on 18.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

typealias ButtonLayout = [[Button]]

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
                            ButtonView(button: button, isToggled: viewModel.buttonDisplayViewMode == .alternate && button == .other(.alternate)) {
                                viewModel.buttonPressed = button
                            } longPress: {
                                viewModel.buttonLongPressed = button
                            }
                            .font(.system(for: geometry))
                        }
                    }
                }
            }
        }
        .background(Rectangle().fill(theme.primaryColour).frame(maxWidth: .infinity, maxHeight: .infinity))
    }
}

extension Button {
    static func layout(for buttonDisplayViewMode: ButtonDisplayView.Mode) -> ButtonLayout {
        switch buttonDisplayViewMode {
        case .normal:
            return .normalButtonsLayout
        case .alternate:
            return .alternateButtonsLayout
        }
    }
}

extension ButtonLayout {
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

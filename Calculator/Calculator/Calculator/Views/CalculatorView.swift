//
//  CalculatorView.swift
//  Swift Calculator
//
//  Created by Alex Müller on 16.05.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

typealias ButtonLayout = [[Button]]

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
        ZStack {
            if colorScheme == .dark {
                Color.black.edgesIgnoringSafeArea(.all)
            } else {
                Color.white.edgesIgnoringSafeArea(.all)
            }
            
            Text(text)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
}

struct ButtonDisplayView: View {
    enum Mode {
        case normal
        case alternate
    }
        
    @Environment(\.colorScheme) var colorScheme
    
    let mode: Mode
    
    var body: some View {
        VStack {
            ForEach(Array(Button.layout(for: mode)), id:\.self) { row in
                HStack {
                    ForEach(Array(row), id: \.self) { button in
                        Text(button.rawValue)
                    }
                }
            }
        }
    }
}

struct CalculatorView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject fileprivate var viewModel: CalculatorViewModel
    
    let kInactiveButtonColor: UIColor = .brown
    let kActiveButtonColor: UIColor = .orange
    let kViewMargin: CGFloat = 2
    let kLabelFontToHeightRatio: CGFloat = 0.33
    let kAspectRatioThreshold: CGFloat = 0.75
    
    var body: some View {
        ZStack {
            if colorScheme == .light {
                Color.black.edgesIgnoringSafeArea(.all)
            } else {
                Color.white.edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 2) {
                TextDisplayField(text: viewModel.expressionText + "=", size: .small)
                TextDisplayField(text: viewModel.currentValue.toSimpleNumericString(for: .fullDisplay), size: .large)
                ButtonDisplayView(mode: viewModel.buttonDisplayViewMode)
            }
        }
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

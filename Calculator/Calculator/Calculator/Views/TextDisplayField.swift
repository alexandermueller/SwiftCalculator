//
//  TextDisplayField.swift
//  Swift Calculator
//
//  Created by Alex Müller on 18.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

struct TextDisplayField: View {
    @EnvironmentObject var theme: Theme
    @State var presentHint: Bool = false

    let text: String
    let hint: String?

    private var infoButtonScale = 0.7

    init(text: String, hint: String? = nil) {
        self.text = text
        self.hint = hint
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                HStack {
                    if hint != nil {
                        Spacer()
                            .frame(width: infoButtonFootprint(for: geometry))
                    }

                    Text(text)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .font(.system(for: geometry))
                        .multilineTextAlignment(.trailing)
                }

                if let hint {
                    SwiftUI.Button("ⓘ") {
                        presentHint.toggle()
                    }
                    .padding(20)
                    .font(.system(for: geometry, scale: infoButtonScale, bold: true))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .foregroundColor(.accentColor)
                            .padding(15)
                    )
                    .popover(isPresented: $presentHint, arrowEdge: .top) {
                        Text(hint)
                            .padding(15)
                            .font(.system(for: geometry, scale: 0.5))
                            .foregroundColor(theme.textDisplayFieldForegroundColour)
                            .presentationCompactAdaptation(.popover)
                            .interactiveDismissDisabled()
                    }
                }
            }
        }
        .background(theme.textDisplayFieldBackgroundColour)
    }

    func infoButtonFootprint(for geometry: GeometryProxy) -> Double {
        geometry.size.height * infoButtonScale * Theme.labelFontToHeightRatio + 30.0
    }
}

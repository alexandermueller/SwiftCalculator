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
    @State var showHint: Bool = true

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
                Text(text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .font(.system(for: geometry))
                    .multilineTextAlignment(.trailing)
                    .padding(.leading, hint == nil ? 0 : infoButtonFootprint(for: geometry))
                
                if let hint {
                    SwiftUI.Button("ⓘ") {
                        showHint.toggle()
                    }
                    .padding(10)
                    .font(.system(for: geometry, scale: infoButtonScale, bold: true))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .foregroundColor(.accentColor)
                            .padding(7)
                    )
                    .popover(isPresented: $showHint) {
                        Text(hint)
                            .padding(15)
                            .font(.system(for: geometry, scale: 0.5))
                            .foregroundColor(theme.textDisplayFieldForegroundColour)
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
        .background(theme.textDisplayFieldBackgroundColour)
        .onDisappear {
            
        }
    }

    func infoButtonFootprint(for geometry: GeometryProxy) -> Double {
        (geometry.size.height + 10.0) * (1 - infoButtonScale)
    }
}

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

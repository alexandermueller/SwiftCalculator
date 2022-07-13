//
//  VariableDisplayView.swift
//  Swift Calculator
//
//  Created by Alex Müller on 18.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import SwiftUI

typealias VariableValuePair = (variable: Variable, value: MaxPrecisionNumber)

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

extension VariableValueDict {
    var sortedKeyValuePairArray: [VariableValuePair] {
        Variable.allCases.map { ($0, self[$0, default: 0]) }
    }
}

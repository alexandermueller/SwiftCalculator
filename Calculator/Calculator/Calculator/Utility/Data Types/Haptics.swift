//
//  Haptics.swift
//  Swift Calculator
//
//  Created by Alex Müller on 16.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import UIKit

class Haptics {
    static let shared = Haptics()
    
    private init() {}
    
    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
    
    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
}

//
//  Haptics.swift
//  Swift Calculator
//
//  Created by Alex Müller on 16.06.22.
//  Copyright © 2022 Alexander Mueller. All rights reserved.
//

import UIKit

@MainActor
class Haptics {
    static let shared = Haptics()
    
    private init() {}
    
    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard Preferences.shared.hapticsEnabled else {
            return
        }

        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
    
    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        guard Preferences.shared.hapticsEnabled else {
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
}

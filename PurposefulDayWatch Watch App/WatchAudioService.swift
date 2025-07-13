//
//  WatchAudioService.swift
//  PurposefulDayWatch Watch App
//
//  Created by John Abraham on 7/13/25.
//

import Foundation
import WatchKit

/// Service responsible for playing audio cues and haptic feedback on the Watch
class WatchAudioService {
    // MARK: - Singleton
    /// Shared instance for easy access throughout the app
    static let shared = WatchAudioService()
    
    // MARK: - Sound Types
    enum SoundType {
        case taskStart
        case taskComplete
        case activityComplete
        case countdown
    }
    
    // MARK: - Initialization
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    // MARK: - Haptic Feedback
    
    /// Provide haptic feedback
    /// - Parameter type: The type of haptic feedback
    func playHaptic(for type: SoundType) {
        switch type {
        case .taskStart:
            WKInterfaceDevice.current().play(.start)
        case .taskComplete:
            WKInterfaceDevice.current().play(.success)
        case .activityComplete:
            // Play a stronger haptic for activity completion
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WKInterfaceDevice.current().play(.success)
            }
        case .countdown:
            // Use a distinct haptic for countdown
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    /// Provide notification haptic feedback
    func notificationHaptic() {
        WKInterfaceDevice.current().play(.notification)
    }
    
    /// Provide click haptic feedback
    func clickHaptic() {
        WKInterfaceDevice.current().play(.click)
    }
}

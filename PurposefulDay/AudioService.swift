//
//  AudioService.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import Foundation
import AVFoundation
import UIKit

/// Service responsible for playing audio cues
class AudioService {
    // MARK: - Singleton
    /// Shared instance for easy access throughout the app
    static let shared = AudioService()
    
    // MARK: - Audio Players
    private var audioPlayers: [URL: AVAudioPlayer] = [:]
    
    // MARK: - Sound Types
    enum SoundType {
        case taskStart
        case taskComplete
        case activityComplete
        case countdown
        
        /// Get the filename for the sound type
        var filename: String {
            switch self {
            case .taskStart:
                return "task_start.mp3"
            case .taskComplete:
                return "task_complete.mp3"
            case .activityComplete:
                return "activity_complete.mp3"
            case .countdown:
                return "countdown.mp3"
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Set up audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Play Sound
    
    /// Play a sound effect
    /// - Parameter type: The type of sound to play
    func playSound(_ type: SoundType) {
        guard let url = Bundle.main.url(forResource: type.filename, withExtension: nil) else {
            print("Sound file not found: \(type.filename)")
            // Fall back to system sound if custom sound is not available
            playSystemSound(for: type)
            return
        }
        
        if let player = audioPlayers[url] {
            player.currentTime = 0
            player.play()
        } else {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                audioPlayers[url] = player
                player.play()
            } catch {
                print("Failed to play sound: \(error)")
                // Fall back to system sound if custom sound fails
                playSystemSound(for: type)
            }
        }
    }
    
    /// Play a system sound as fallback
    /// - Parameter type: The type of sound to play
    private func playSystemSound(for type: SoundType) {
        var soundID: SystemSoundID
        
        switch type {
        case .taskStart:
            soundID = 1000 // System sound ID for notification
        case .taskComplete:
            soundID = 1001 // System sound ID for notification
        case .activityComplete:
            soundID = 1002 // System sound ID for notification
        case .countdown:
            soundID = 1003 // System sound ID for notification
        }
        
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - Haptic Feedback
    
    /// Provide haptic feedback
    /// - Parameter style: The style of haptic feedback
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Provide notification haptic feedback
    /// - Parameter type: The type of notification feedback
    func notificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

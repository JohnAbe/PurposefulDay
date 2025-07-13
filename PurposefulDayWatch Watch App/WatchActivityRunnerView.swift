//
//  WatchActivityRunnerView.swift
//  PurposefulDayWatch Watch App
//
//  Created by John Abraham on 6/29/25.
//

import SwiftUI

struct WatchActivityRunnerView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared
    @State private var activity: Activity?
    @State private var currentTaskIndex: Int = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var timer: Timer? = nil
    @State private var lastUpdateTime: Date = Date()
    @State private var showBackConfirmation: Bool = false
    
    // Audio service for haptic feedback
    private let audioService = WatchAudioService.shared
    
    // MARK: - Timer Functions
    
    /// Start the timer for timed tasks
    private func startTimer() {
        // Only start the timer if we're not paused
        guard !isPaused else { return }
        
        isRunning = true
        timer?.invalidate()
        
        // Record the time when we start the timer
        lastUpdateTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            // Only decrement time if we're running and not paused
            if self.isRunning && !self.isPaused {
                // Calculate elapsed time since last update
                let now = Date()
                let elapsed = now.timeIntervalSince(self.lastUpdateTime)
                self.lastUpdateTime = now
                
                // Only decrement if there's time remaining
                if self.timeRemaining > 0 {
                    // Decrement by actual elapsed time (capped at 1 second to prevent large jumps)
                    let decrementAmount = min(elapsed, 1.0)
                    self.timeRemaining -= decrementAmount
                    
                    // Play countdown sound for last 3 seconds
                    if self.timeRemaining <= 3 && self.timeRemaining > 0 {
                        self.audioService.playHaptic(for: .countdown)
                    }
                } else {
                    self.stopTimer()
                    // Notify the phone that the task is complete, but only if we're still running
                    // This prevents auto-progression when paused
                    if self.isRunning && !self.isPaused {
                        self.connectivityManager.skipTask()
                    }
                }
            }
        }
    }
    
    /// Stop the timer
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    /// Pause the timer
    private func pauseTimer() {
        isPaused = true
        // We don't invalidate the timer, just set isPaused flag
        // This allows us to keep the UI updating without decrementing time
    }
    
    /// Resume the timer
    private func resumeTimer() {
        isPaused = false
        lastUpdateTime = Date() // Reset the last update time
        // The existing timer will continue running
    }
    
    /// Format time interval to string
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Navigate back to the activity list
    private func navigateBack() {
        showBackConfirmation = false
        
        // Stop the local timer first
        stopTimer()
        
        // First pause the activity if it's running
        connectivityManager.pauseActivity()
        
        // Then send the navigate command
        connectivityManager.sendCommand(.navigateToList)
        
        // Force update the UI state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToList"), object: nil)
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                if let activity = activity {
                    if currentTaskIndex < activity.tasks.count {
                        let task = activity.tasks[currentTaskIndex]
                        
                        Text(activity.name)
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text(task.name)
                            .font(.body)
                            .padding(.bottom, 10)
                        
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .padding(.bottom, 10)
                        
                        VStack {
                            HStack {
                                Button(action: {
                                    if !isPaused {
                                        pauseTimer()
                                        connectivityManager.pauseActivity()
                                        audioService.clickHaptic()
                                    } else {
                                        resumeTimer()
                                        connectivityManager.resumeActivity()
                                        audioService.clickHaptic()
                                    }
                                }) {
                                    Image(systemName: !isPaused ? "pause.fill" : "play.fill")
                                        .font(.system(size: 20))
                                        .frame(width: 40, height: 40)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                
                                Button(action: {
                                    connectivityManager.skipTask()
                                    audioService.clickHaptic()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 20))
                                        .frame(width: 40, height: 40)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                
                                Button(action: {
                                    connectivityManager.extendTime()
                                    audioService.clickHaptic()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .frame(width: 40, height: 40)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                            }
                            
                            Button(action: {
                                if isRunning {
                                    showBackConfirmation = true
                                } else {
                                    navigateBack()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back to Activities")
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        Text("Activity Completed!")
                            .font(.headline)
                    }
                } else {
                    Text("No activity running")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        navigateBack()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back to Activities")
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            }
            
            // Confirmation dialog for going back while activity is running
            if showBackConfirmation {
                VStack {
                    Text("Pause activity and go back?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    HStack {
                        Button("Cancel") {
                            showBackConfirmation = false
                            audioService.clickHaptic()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Confirm") {
                            connectivityManager.pauseActivity()
                            audioService.clickHaptic()
                            navigateBack()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .onAppear {
            // Set up the activity update handler
            connectivityManager.activityUpdateHandler = { activity, taskIndex in
                let wasRunningBefore = self.isRunning
                let wasPausedBefore = self.isPaused
                
                self.activity = activity
                self.currentTaskIndex = taskIndex
                
                if taskIndex < activity.tasks.count {
                    let task = activity.tasks[taskIndex]
                    
                    // Calculate the actual time remaining based on progress
                    // Subtract the progress from the total duration
                    self.timeRemaining = task.duration - Double(task.progress)
                    
                    // Check if the activity is paused on the phone
                    // We can infer this from the task state
                    let isActivityPaused = task.progress > 0 && !task.isCompleted
                    
                    // Update our local state to match the phone's state
                    if isActivityPaused != self.isPaused {
                        self.isPaused = isActivityPaused
                    }
                    
                    // Handle timer state based on activity state
                    if !self.isRunning {
                        // If we weren't running before, start the timer
                        self.startTimer()
                    } else if wasPausedBefore != self.isPaused {
                        // If pause state changed, update timer accordingly
                        if self.isPaused {
                            self.pauseTimer()
                        } else {
                            self.resumeTimer()
                        }
                    }
                    
                    // Play haptic feedback for task start if this is a new task
                    if !wasRunningBefore || self.currentTaskIndex != taskIndex {
                        self.audioService.playHaptic(for: .taskStart)
                    }
                } else {
                    self.stopTimer()
                    
                    // Play haptic feedback for activity completion
                    self.audioService.playHaptic(for: .activityComplete)
                }
            }
            
            // Set up the activity control handler
            connectivityManager.activityControlHandler = { command, data in
                switch command {
                case .pauseActivity:
                    self.isPaused = true
                    self.pauseTimer()
                    self.audioService.clickHaptic()
                case .resumeActivity:
                    self.isPaused = false
                    self.resumeTimer()
                    self.audioService.clickHaptic()
                case .skipTask:
                    // The iPhone will send an updated activity state
                    self.audioService.playHaptic(for: .taskComplete)
                    break
                case .extendTime:
                    if let seconds = data?["seconds"] as? Int {
                        self.timeRemaining += Double(seconds)
                        self.audioService.clickHaptic()
                    }
                case .activityCompleted:
                    self.audioService.playHaptic(for: .activityComplete)
                    self.navigateBack()
                default:
                    break
                }
            }
        }
    }
}

struct WatchActivityRunnerView_Previews: PreviewProvider {
    static var previews: some View {
        WatchActivityRunnerView()
    }
}

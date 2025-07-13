//
//  ActivityRunnerViewModel.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import Foundation
import Combine
import SwiftUI
import UIKit
import WatchConnectivity

/// View model for running an activity
class ActivityRunnerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The activity being run
    @Published var activity: Activity
    
    /// The current task being executed
    @Published var currentTask: ActivityTask?
    
    /// The index of the current task
    @Published var currentTaskIndex: Int = 0
    
    /// Whether the activity is currently running
    @Published var isRunning: Bool = false
    
    /// Whether the activity is paused
    @Published var isPaused: Bool = false
    
    /// Whether the activity is completed
    @Published var isCompleted: Bool = false
    
    /// The time remaining for the current task (for timed tasks)
    @Published var timeRemaining: Int = 0
    
    /// The progress of the current task (for count tasks)
    @Published var currentProgress: Int = 0
    
    /// The next task (if any)
    @Published var nextTask: ActivityTask?
    
    /// Whether to show the countdown
    @Published var showCountdown: Bool = false
    
    /// The countdown value
    @Published var countdownValue: Int = 3
    
    // MARK: - Private Properties
    
    /// The timer for timed tasks
    private var timer: Timer?
    
    /// The countdown timer
    private var countdownTimer: Timer?
    
    /// The data service for persistence
    private let dataService = DataService.shared
    
    /// The audio service for sound effects
    private let audioService = AudioService.shared
    
    /// The watch connectivity manager
    private let watchConnectivityManager = WatchConnectivityManager.shared
    
    /// The completed tasks
    private var completedTasks: [CompletedTask] = []
    
    /// The callback when the activity is completed
    private let onComplete: (CompletedActivity) -> Void
    
    // MARK: - Initialization
    
    /// Initialize with an activity and completion callback
    /// - Parameters:
    ///   - activity: The activity to run
    ///   - onComplete: Callback when the activity is completed
    init(activity: Activity, onComplete: @escaping (CompletedActivity) -> Void) {
        self.activity = activity
        self.onComplete = onComplete
        
        // Reset the activity state
        resetActivity()
        
        // Set up watch connectivity handler
        watchConnectivityManager.activityControlHandler = { [weak self] command, data in
            self?.handleWatchCommand(command, data: data)
        }
    }
    
    // MARK: - Activity Control
    
    /// Start the activity
    func startActivity() {
        guard !activity.tasks.isEmpty else { return }
        
        // Start with a countdown
        startCountdown()
    }
    
    /// Start an activity by ID (used when starting from Watch)
    /// - Parameter activityId: The ID of the activity to start
    func startActivityById(_ activityId: UUID) {
        // Find the activity by ID
        let dataService = DataService.shared
        let activities = dataService.loadActivities()
        
        if let activity = activities.first(where: { $0.id == activityId }) {
            self.activity = activity
            resetActivity()
            startActivity()
        }
    }
    
    /// Start the countdown before beginning the activity
    private func startCountdown() {
        showCountdown = true
        countdownValue = 3
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.countdownValue > 1 {
                self.countdownValue -= 1
                self.audioService.playSound(.countdown)
            } else {
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.showCountdown = false
                
                // Actually start the activity
                self.beginActivity()
            }
        }
    }
    
    /// Begin the activity after countdown
    private func beginActivity() {
        isRunning = true
        isPaused = false
        
        // Start the first task
        startCurrentTask()
        
        // Send activity update to Watch
        sendActivityUpdateToWatch()
    }
    
    /// Pause the activity
    func pauseActivity() {
        isPaused = true
        timer?.invalidate()
        
        // Update the current task's progress to reflect the pause
        if let task = currentTask, task.durationType == .timed {
            var updatedTask = task
            updatedTask.progress = task.duration - timeRemaining
            updateCurrentTask(updatedTask)
        }
        
        // Send activity update to Watch
        sendActivityUpdateToWatch()
        
        // Also send explicit pause command to ensure watch gets it
        watchConnectivityManager.sendCommand(.pauseActivity)
    }
    
    /// Resume the activity
    func resumeActivity() {
        isPaused = false
        
        if let currentTask = currentTask, currentTask.durationType == .timed {
            startTimer()
        }
        
        // Send activity update to Watch
        sendActivityUpdateToWatch()
        
        // Also send explicit resume command to ensure watch gets it
        watchConnectivityManager.sendCommand(.resumeActivity)
    }
    
    /// Stop the activity
    func stopActivity() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        // Reset the activity state
        resetActivity()
    }
    
    /// Reset the activity state
    private func resetActivity() {
        currentTaskIndex = 0
        currentTask = activity.tasks.first
        nextTask = activity.tasks.count > 1 ? activity.tasks[1] : nil
        isCompleted = false
        completedTasks = []
        
        // Reset all tasks
        for i in 0..<activity.tasks.count {
            activity.tasks[i].isCompleted = false
            activity.tasks[i].progress = 0
        }
        
        // Set up initial time remaining
        if let task = currentTask, task.durationType == .timed {
            timeRemaining = task.duration
        }
    }
    
    // MARK: - Task Control
    
    /// Start the current task
    private func startCurrentTask() {
        guard let task = currentTask else { return }
        
        // Play start sound
        audioService.playSound(.taskStart)
        audioService.hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle.medium)
        
        // Set up the task based on its type
        switch task.durationType {
        case .timed:
            timeRemaining = task.duration
            startTimer()
        case .count:
            currentProgress = task.progress
        }
    }
    
    /// Start the timer for timed tasks
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused, let task = self.currentTask, task.durationType == .timed else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                
                // Update the task progress
                var updatedTask = task
                updatedTask.progress = task.duration - self.timeRemaining
                self.updateCurrentTask(updatedTask)
                
                // Play countdown sound for last 3 seconds
                if self.timeRemaining <= 3 && self.timeRemaining > 0 {
                    self.audioService.playSound(.countdown)
                }
            } else {
                // Task completed
                self.completeCurrentTask()
            }
        }
    }
    
    /// Update the current task
    /// - Parameter task: The updated task
    private func updateCurrentTask(_ task: ActivityTask) {
        guard let index = activity.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        activity.tasks[index] = task
        currentTask = task
        
        // Send activity update to Watch
        sendActivityUpdateToWatch()
    }
    
    /// Send the current activity state to the Watch
    private func sendActivityUpdateToWatch() {
        // Make sure the activity state is up-to-date before sending
        if let task = currentTask, task.durationType == .timed {
            var updatedTask = task
            updatedTask.progress = task.duration - timeRemaining
            
            // Only update if the progress has changed
            if updatedTask.progress != task.progress {
                updateCurrentTask(updatedTask)
            }
        }
        
        watchConnectivityManager.sendActivityUpdate(activity: activity, currentTaskIndex: currentTaskIndex)
    }
    
    /// Complete the current task
    func completeCurrentTask() {
        guard let task = currentTask else { return }
        
        // Stop the timer
        timer?.invalidate()
        
        // Mark the task as completed
        var completedTask = task
        completedTask.isCompleted = true
        updateCurrentTask(completedTask)
        
        // Play completion sound
        audioService.playSound(.taskComplete)
        audioService.notificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType.success)
        
        // Add to completed tasks
        let actualDuration = task.durationType == .timed ? task.duration : task.progress
        let completedTaskRecord = CompletedTask(from: completedTask, actualDuration: actualDuration)
        completedTasks.append(completedTaskRecord)
        
        // Move to the next task or complete the activity
        moveToNextTask()
        
        // Send activity update to Watch
        sendActivityUpdateToWatch()
        
        // Also send explicit skip task command to ensure watch gets it
        watchConnectivityManager.sendCommand(.skipTask)
    }
    
    /// Move to the next task
    private func moveToNextTask() {
        currentTaskIndex += 1
        
        if currentTaskIndex < activity.tasks.count {
            // Move to the next task
            currentTask = activity.tasks[currentTaskIndex]
            nextTask = currentTaskIndex + 1 < activity.tasks.count ? activity.tasks[currentTaskIndex + 1] : nil
            
            // Start the next task
            startCurrentTask()
        } else {
            // All tasks completed
            completeActivity()
        }
    }
    
    /// Complete the activity
    private func completeActivity() {
        isRunning = false
        isCompleted = true
        
        // Play completion sound
        audioService.playSound(.activityComplete)
        audioService.notificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType.success)
        
        // Create completed activity record
        let completedActivity = CompletedActivity(from: activity, with: completedTasks)
        
        // Send activity update to Watch
        sendActivityUpdateToWatch()
        
        // Call the completion callback
        onComplete(completedActivity)
    }
    
    // MARK: - Task Control Extensions
    
    /// Extend the time for a timed task by a specified number of seconds
    /// - Parameter seconds: The number of seconds to add
    func extendTime(by seconds: Int = 10) {
        guard let task = currentTask, task.durationType == .timed, !task.isCompleted else { return }
        
        // Add time to the remaining time
        timeRemaining += seconds
        
        // Update the task's duration to reflect the extension
        var updatedTask = task
        updatedTask.duration += seconds
        updateCurrentTask(updatedTask)
        
        // Provide feedback
        audioService.hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle.light)
        
        // Send activity update to Watch
        sendActivityUpdateToWatch()
        
        // Also send explicit extend time command to ensure watch gets it
        watchConnectivityManager.sendCommand(.extendTime, data: ["seconds": seconds])
    }
    
    // MARK: - Task Progress
    
    /// Increment the progress for count-based tasks
    func incrementProgress() {
        guard let task = currentTask, task.durationType == .count, !task.isCompleted else { return }
        
        currentProgress += 1
        
        // Update the task progress
        var updatedTask = task
        updatedTask.progress = currentProgress
        updateCurrentTask(updatedTask)
        
        // Check if the task is completed
        if currentProgress >= task.duration {
            completeCurrentTask()
        }
    }
    
    /// Decrement the progress for count-based tasks
    func decrementProgress() {
        guard let task = currentTask, task.durationType == .count, currentProgress > 0 else { return }
        
        currentProgress -= 1
        
        // Update the task progress
        var updatedTask = task
        updatedTask.progress = currentProgress
        updateCurrentTask(updatedTask)
    }
    
    // MARK: - Formatting
    
    /// Format the time remaining for display
    /// - Returns: Formatted time string
    func formattedTimeRemaining() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Calculate the progress percentage for the current task
    /// - Returns: Progress percentage (0-100)
    func progressPercentage() -> Double {
        guard let task = currentTask else { return 0 }
        
        switch task.durationType {
        case .timed:
            guard task.duration > 0 else { return 0 }
            return Double(task.duration - timeRemaining) / Double(task.duration) * 100.0
        case .count:
            guard task.duration > 0 else { return 0 }
            return Double(currentProgress) / Double(task.duration) * 100.0
        }
    }
    
    // MARK: - Cleanup
    
    /// Clean up resources when the view model is no longer needed
    func cleanup() {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    // MARK: - Watch Connectivity
    
    /// Handle commands from the Watch
    /// - Parameters:
    ///   - command: The command received
    ///   - data: Additional data for the command
    private func handleWatchCommand(_ command: WatchMessage, data: [String: Any]?) {
        switch command {
        case .startActivity:
            if let activityIdString = data?["activityId"] as? String,
               let activityId = UUID(uuidString: activityIdString) {
                startActivityById(activityId)
            }
        case .pauseActivity:
            // Only pause if we're not already paused
            if !isPaused {
                pauseActivity()
            }
        case .resumeActivity:
            // Only resume if we're currently paused
            if isPaused {
                resumeActivity()
            }
        case .skipTask:
            completeCurrentTask()
        case .extendTime:
            let seconds = data?["seconds"] as? Int ?? 10
            extendTime(by: seconds)
        case .navigateToList:
            // If the watch wants to navigate back to the list, pause the activity
            if !isPaused {
                pauseActivity()
            }
        default:
            break
        }
        
        // After handling any command, send an activity update to ensure
        // the watch has the latest state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sendActivityUpdateToWatch()
        }
    }
    
    deinit {
        cleanup()
    }
}

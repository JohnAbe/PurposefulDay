//
//  Activity.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import Foundation

// MARK: - Activity
/// Represents a sequence of tasks that can be executed
struct Activity: Identifiable, Codable {
    /// Unique identifier for the activity
    var id = UUID()
    /// Name of the activity
    var name: String
    /// List of tasks in the activity
    var tasks: [ActivityTask]
    /// Whether the activity has been completed
    var isCompleted: Bool = false
    /// When the activity was created
    var createdAt: Date = Date()
    /// When the activity was last completed (if ever)
    var lastCompletedAt: Date?
    
    init(name: String, tasks: [ActivityTask] = []) {
        self.name = name
        self.tasks = tasks
    }
    
    /// Calculate the total duration of the activity (for timed tasks only)
    var totalDuration: Int {
        return tasks
            .filter { $0.durationType == .timed }
            .reduce(0) { $0 + $1.duration }
    }
    
    /// Format the total duration for display
    func formattedTotalDuration() -> String {
        let seconds = totalDuration
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return remainingSeconds > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(minutes)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    /// Get the number of tasks by type
    func taskCountByType() -> (timed: Int, count: Int) {
        let timedCount = tasks.filter { $0.durationType == .timed }.count
        let countCount = tasks.filter { $0.durationType == .count }.count
        return (timedCount, countCount)
    }
}

// MARK: - Completed Activity
/// Record of a completed activity for history tracking
struct CompletedActivity: Identifiable, Codable {
    /// Unique identifier for the completed activity
    var id = UUID()
    /// Reference to the original activity
    var activityId: UUID
    /// Name of the activity
    var name: String
    /// When the activity was completed
    var completedAt: Date
    /// List of completed tasks
    var tasks: [CompletedTask]
    
    init(from activity: Activity, with completedTasks: [CompletedTask]) {
        self.activityId = activity.id
        self.name = activity.name
        self.completedAt = Date()
        self.tasks = completedTasks
    }
    
    /// Calculate the total duration of the completed activity
    var totalDuration: Int {
        return tasks.reduce(0) { $0 + $1.actualDuration }
    }
    
    /// Format the total duration for display
    func formattedTotalDuration() -> String {
        let seconds = totalDuration
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return remainingSeconds > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(minutes)m"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

// MARK: - Sample Data
extension Activity {
    /// Sample activities for preview and testing
    static let samples = [
        Activity(
            name: "Push-day Workout",
            tasks: [
                ActivityTask(name: "Push Ups", durationType: .timed, duration: 40),
                ActivityTask(name: "Rest", durationType: .timed, duration: 20),
                ActivityTask(name: "Bear Crawl", durationType: .timed, duration: 40),
                ActivityTask(name: "Rest", durationType: .timed, duration: 20),
                ActivityTask(name: "Mountain Climbers", durationType: .timed, duration: 40),
                ActivityTask(name: "Rest", durationType: .timed, duration: 20)
            ]
        ),
        Activity(
            name: "Maximum Effort Workout",
            tasks: [
                ActivityTask(name: "Push Ups", durationType: .count, duration: 100),
                ActivityTask(name: "Rest", durationType: .timed, duration: 60),
                ActivityTask(name: "Squats", durationType: .count, duration: 50),
                ActivityTask(name: "Rest", durationType: .timed, duration: 60),
                ActivityTask(name: "Sit Ups", durationType: .count, duration: 30)
            ]
        )
    ]
}

extension BaseTask {
    /// Sample base tasks for preview and testing
    static let samples = [
        BaseTask(name: "Push Ups", defaultDurationType: .timed, defaultDuration: 40),
        BaseTask(name: "Rest", defaultDurationType: .timed, defaultDuration: 20),
        BaseTask(name: "Bear Crawl", defaultDurationType: .timed, defaultDuration: 40),
        BaseTask(name: "Mountain Climbers", defaultDurationType: .timed, defaultDuration: 40),
        BaseTask(name: "Squats", defaultDurationType: .count, defaultDuration: 50),
        BaseTask(name: "Sit Ups", defaultDurationType: .count, defaultDuration: 30)
    ]
}

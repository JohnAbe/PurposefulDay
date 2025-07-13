//
//  Task.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import Foundation

// MARK: - Task Duration Type
/// Defines how a task's duration is measured
enum TaskDurationType: String, Codable {
    /// Task is measured in time (seconds)
    case timed
    /// Task is measured in count/repetitions
    case count
}

// MARK: - Base Task
/// A reusable task template that can be used across multiple activities
struct BaseTask: Identifiable, Codable {
    /// Unique identifier for the task
    var id = UUID()
    /// Name of the task
    var name: String
    /// Default duration type (timed or count)
    var defaultDurationType: TaskDurationType
    /// Default duration value (seconds for timed, repetitions for count)
    var defaultDuration: Int
    
    init(name: String, defaultDurationType: TaskDurationType, defaultDuration: Int) {
        self.name = name
        self.defaultDurationType = defaultDurationType
        self.defaultDuration = defaultDuration
    }
}

// MARK: - Activity Task
/// A task that is part of an activity
struct ActivityTask: Identifiable, Codable {
    /// Unique identifier for the task
    var id = UUID()
    /// Optional reference to a base task (for reusability)
    var baseTaskId: UUID?
    /// Name of the task
    var name: String
    /// Duration type (timed or count)
    var durationType: TaskDurationType
    /// Duration value (seconds for timed, repetitions for count)
    var duration: Int
    /// Whether the task has been completed
    var isCompleted: Bool = false
    /// Current progress (seconds elapsed or repetitions completed)
    var progress: Int = 0
    
    init(name: String, durationType: TaskDurationType, duration: Int, baseTaskId: UUID? = nil) {
        self.name = name
        self.durationType = durationType
        self.duration = duration
        self.baseTaskId = baseTaskId
    }
    
    /// Create an ActivityTask from a BaseTask
    init(from baseTask: BaseTask) {
        self.name = baseTask.name
        self.durationType = baseTask.defaultDurationType
        self.duration = baseTask.defaultDuration
        self.baseTaskId = baseTask.id
    }
    
    /// Calculate the completion percentage of the task
    var completionPercentage: Double {
        guard duration > 0 else { return 0 }
        return min(Double(progress) / Double(duration) * 100.0, 100.0)
    }
    
    /// Format the duration for display
    func formattedDuration() -> String {
        switch durationType {
        case .timed:
            if duration < 60 {
                return "\(duration)s"
            } else {
                let minutes = duration / 60
                let seconds = duration % 60
                return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
            }
        case .count:
            return "\(duration) reps"
        }
    }
    
    /// Format the progress for display
    func formattedProgress() -> String {
        switch durationType {
        case .timed:
            if progress < 60 {
                return "\(progress)s"
            } else {
                let minutes = progress / 60
                let seconds = progress % 60
                return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
            }
        case .count:
            return "\(progress)/\(duration)"
        }
    }
}

// MARK: - Completed Task
/// Record of a completed task for history tracking
struct CompletedTask: Identifiable, Codable {
    /// Unique identifier for the completed task
    var id = UUID()
    /// Name of the task
    var name: String
    /// Duration type (timed or count)
    var durationType: TaskDurationType
    /// Planned duration
    var plannedDuration: Int
    /// Actual duration taken to complete
    var actualDuration: Int
    /// When the task was completed
    var completedAt: Date
    
    init(from activityTask: ActivityTask, actualDuration: Int) {
        self.name = activityTask.name
        self.durationType = activityTask.durationType
        self.plannedDuration = activityTask.duration
        self.actualDuration = actualDuration
        self.completedAt = Date()
    }
}

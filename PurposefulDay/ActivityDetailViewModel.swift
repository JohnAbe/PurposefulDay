//
//  ActivityDetailViewModel.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import Foundation
import Combine

/// View model for managing the details of an activity
class ActivityDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The activity being edited
    @Published var activity: Activity
    
    /// Available base tasks for reuse
    @Published var availableBaseTasks: [BaseTask] = []
    
    /// Whether changes have been made
    @Published var hasChanges: Bool = false
    
    // MARK: - Private Properties
    
    /// The data service for persistence
    private let dataService = DataService.shared
    
    /// The callback to update the activity in the parent view model
    private let onUpdate: (Activity) -> Void
    
    // MARK: - Initialization
    
    /// Initialize with an activity and update callback
    /// - Parameters:
    ///   - activity: The activity to edit
    ///   - onUpdate: Callback when the activity is updated
    init(activity: Activity, onUpdate: @escaping (Activity) -> Void) {
        self.activity = activity
        self.onUpdate = onUpdate
        
        // Load available base tasks
        loadBaseTasks()
    }
    
    // MARK: - Data Loading
    
    /// Load available base tasks
    private func loadBaseTasks() {
        availableBaseTasks = dataService.loadBaseTasks()
    }
    
    // MARK: - Task Management
    
    /// Add a task to the activity
    /// - Parameter task: The task to add
    func addTask(_ task: ActivityTask) {
        activity.tasks.append(task)
        updateActivity()
    }
    
    /// Update a task in the activity
    /// - Parameter task: The updated task
    func updateTask(_ task: ActivityTask) {
        if let index = activity.tasks.firstIndex(where: { $0.id == task.id }) {
            activity.tasks[index] = task
            updateActivity()
        }
    }
    
    /// Delete tasks from the activity
    /// - Parameter indexSet: The indices of tasks to delete
    func deleteTasks(at indexSet: IndexSet) {
        activity.tasks.remove(atOffsets: indexSet)
        updateActivity()
    }
    
    /// Move tasks within the activity
    /// - Parameters:
    ///   - source: The source indices
    ///   - destination: The destination index
    func moveTasks(from source: IndexSet, to destination: Int) {
        activity.tasks.move(fromOffsets: source, toOffset: destination)
        updateActivity()
    }
    
    /// Create a new task from scratch
    /// - Parameters:
    ///   - name: The name of the task
    ///   - durationType: The duration type (timed or count)
    ///   - duration: The duration value
    /// - Returns: The created task
    func createTask(name: String, durationType: TaskDurationType, duration: Int) -> ActivityTask {
        let task = ActivityTask(name: name, durationType: durationType, duration: duration)
        addTask(task)
        return task
    }
    
    /// Create a task from a base task
    /// - Parameter baseTask: The base task to use as a template
    /// - Returns: The created task
    func createTaskFromBaseTask(_ baseTask: BaseTask) -> ActivityTask {
        let task = ActivityTask(from: baseTask)
        addTask(task)
        return task
    }
    
    // MARK: - Activity Management
    
    /// Update the activity and notify the parent view model
    private func updateActivity() {
        hasChanges = true
        onUpdate(activity)
    }
    
    /// Update the activity name
    /// - Parameter name: The new name
    func updateActivityName(_ name: String) {
        activity.name = name
        updateActivity()
    }
    
    /// Save the activity
    func saveActivity() {
        dataService.saveActivity(activity)
        hasChanges = false
    }
    
    /// Discard changes to the activity
    func discardChanges() {
        // Reload the activity from persistence
        if let reloadedActivity = dataService.loadActivities().first(where: { $0.id == activity.id }) {
            activity = reloadedActivity
        }
        hasChanges = false
    }
    
    // MARK: - Task Completion
    
    /// Toggle the completion status of a task
    /// - Parameter taskId: The ID of the task to toggle
    func toggleTaskCompletion(taskId: UUID) {
        if let index = activity.tasks.firstIndex(where: { $0.id == taskId }) {
            activity.tasks[index].isCompleted.toggle()
            updateActivity()
        }
    }
    
    /// Check if all tasks in the activity are completed
    /// - Returns: True if all tasks are completed
    func areAllTasksCompleted() -> Bool {
        return !activity.tasks.isEmpty && activity.tasks.allSatisfy { $0.isCompleted }
    }
    
    /// Mark the activity as completed
    func markActivityAsCompleted() {
        activity.isCompleted = true
        activity.lastCompletedAt = Date()
        updateActivity()
    }
    
    /// Reset all tasks in the activity
    func resetAllTasks() {
        for index in 0..<activity.tasks.count {
            activity.tasks[index].isCompleted = false
            activity.tasks[index].progress = 0
        }
        activity.isCompleted = false
        updateActivity()
    }
}

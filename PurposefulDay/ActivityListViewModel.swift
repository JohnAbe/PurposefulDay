//
//  ActivityListViewModel.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import Foundation
import Combine
import WatchConnectivity

/// View model for managing the list of activities
class ActivityListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The list of activities
    @Published var activities: [Activity] = []
    
    /// The list of completed activities for history
    @Published var completedActivities: [CompletedActivity] = []
    
    /// The list of base tasks for reuse
    @Published var baseTasks: [BaseTask] = []
    
    /// Whether the data is currently loading
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    /// The data service for persistence
    private let dataService = DataService.shared
    
    /// The watch connectivity manager
    private let watchConnectivityManager = WatchConnectivityManager.shared
    
    // MARK: - Initialization
    
    init() {
        loadData()
        
        // Set up watch connectivity handler
        watchConnectivityManager.activityControlHandler = { [weak self] command, data in
            switch command {
            case .activityList:
                self?.sendActivitiesToWatch()
            case .startActivity:
                if let activityIdString = data?["activityId"] as? String,
                   let activityId = UUID(uuidString: activityIdString),
                   let activity = self?.activities.first(where: { $0.id == activityId }) {
                    // Post a notification to start the activity
                    NotificationCenter.default.post(
                        name: NSNotification.Name("StartActivity"),
                        object: nil,
                        userInfo: ["activityId": activityId]
                    )
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Load all data from persistence
    func loadData() {
        isLoading = true
        
        // Load activities
        activities = dataService.loadActivities()
        
        // Load completed activities
        completedActivities = dataService.loadCompletedActivities()
        
        // Load base tasks
        baseTasks = dataService.loadBaseTasks()
        
        isLoading = false
        
        // Send activities to Watch
        sendActivitiesToWatch()
    }
    
    /// Send the list of activities to the Watch
    private func sendActivitiesToWatch() {
        watchConnectivityManager.sendActivityList(activities)
    }
    
    // MARK: - Activity Management
    
    /// Add a new activity
    /// - Parameter activity: The activity to add
    func addActivity(_ activity: Activity) {
        activities.append(activity)
        dataService.saveActivity(activity)
        
        // Send updated activities to Watch
        sendActivitiesToWatch()
    }
    
    /// Update an existing activity
    /// - Parameter activity: The updated activity
    func updateActivity(_ activity: Activity) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
            dataService.saveActivity(activity)
            
            // Send updated activities to Watch
            sendActivitiesToWatch()
        }
    }
    
    /// Delete an activity
    /// - Parameter indexSet: The indices of activities to delete
    func deleteActivity(at indexSet: IndexSet) {
        for index in indexSet {
            let activity = activities[index]
            dataService.deleteActivity(withId: activity.id)
        }
        activities.remove(atOffsets: indexSet)
        
        // Send updated activities to Watch
        sendActivitiesToWatch()
    }
    
    /// Create a new activity with a name
    /// - Parameter name: The name of the new activity
    /// - Returns: The created activity
    func createActivity(name: String) -> Activity {
        let activity = Activity(name: name)
        addActivity(activity)
        return activity
    }
    
    // MARK: - Base Task Management
    
    /// Add a new base task
    /// - Parameter task: The base task to add
    func addBaseTask(_ task: BaseTask) {
        baseTasks.append(task)
        dataService.saveBaseTask(task)
    }
    
    /// Update an existing base task
    /// - Parameter task: The updated base task
    func updateBaseTask(_ task: BaseTask) {
        if let index = baseTasks.firstIndex(where: { $0.id == task.id }) {
            baseTasks[index] = task
            dataService.saveBaseTask(task)
        }
    }
    
    /// Delete a base task
    /// - Parameter indexSet: The indices of base tasks to delete
    func deleteBaseTask(at indexSet: IndexSet) {
        for index in indexSet {
            let task = baseTasks[index]
            dataService.deleteBaseTask(withId: task.id)
        }
        baseTasks.remove(atOffsets: indexSet)
    }
    
    /// Create a new base task
    /// - Parameters:
    ///   - name: The name of the task
    ///   - durationType: The duration type (timed or count)
    ///   - duration: The default duration
    /// - Returns: The created base task
    func createBaseTask(name: String, durationType: TaskDurationType, duration: Int) -> BaseTask {
        let task = BaseTask(name: name, defaultDurationType: durationType, defaultDuration: duration)
        addBaseTask(task)
        return task
    }
    
    // MARK: - Completed Activity Management
    
    /// Add a completed activity to history
    /// - Parameter completedActivity: The completed activity to add
    func addCompletedActivity(_ completedActivity: CompletedActivity) {
        completedActivities.append(completedActivity)
        dataService.saveCompletedActivity(completedActivity)
        
        // Update the original activity's completion status
        if let index = activities.firstIndex(where: { $0.id == completedActivity.activityId }) {
            var updatedActivity = activities[index]
            updatedActivity.isCompleted = true
            updatedActivity.lastCompletedAt = completedActivity.completedAt
            activities[index] = updatedActivity
            dataService.saveActivity(updatedActivity)
        }
    }
    
    /// Get completed activities for a specific date range
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    /// - Returns: Completed activities within the date range
    func getCompletedActivities(from startDate: Date, to endDate: Date) -> [CompletedActivity] {
        return completedActivities.filter { activity in
            activity.completedAt >= startDate && activity.completedAt <= endDate
        }
    }
    
    /// Get completed activities for the past week
    /// - Returns: Completed activities from the past week
    func getCompletedActivitiesForPastWeek() -> [CompletedActivity] {
        let calendar = Calendar.current
        let now = Date()
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return []
        }
        
        return getCompletedActivities(from: oneWeekAgo, to: now)
    }
}

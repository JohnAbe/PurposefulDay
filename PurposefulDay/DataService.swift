//
//  DataService.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import Foundation

/// Service responsible for data persistence
class DataService {
    // MARK: - UserDefaults Keys
    private let activitiesKey = "purposefulday.activities"
    private let baseTasksKey = "purposefulday.basetasks"
    private let completedActivitiesKey = "purposefulday.completedactivities"
    
    // MARK: - Singleton
    /// Shared instance for easy access throughout the app
    static let shared = DataService()
    
    // MARK: - Activities
    
    /// Load all activities from persistent storage
    func loadActivities() -> [Activity] {
        guard let data = UserDefaults.standard.data(forKey: activitiesKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Activity].self, from: data)
        } catch {
            print("Error decoding activities: \(error)")
            return []
        }
    }
    
    /// Save all activities to persistent storage
    func saveActivities(_ activities: [Activity]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(activities)
            UserDefaults.standard.set(data, forKey: activitiesKey)
        } catch {
            print("Error encoding activities: \(error)")
        }
    }
    
    /// Save a single activity
    func saveActivity(_ activity: Activity) {
        var activities = loadActivities()
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
        } else {
            activities.append(activity)
        }
        saveActivities(activities)
    }
    
    /// Delete an activity
    func deleteActivity(withId id: UUID) {
        var activities = loadActivities()
        activities.removeAll(where: { $0.id == id })
        saveActivities(activities)
    }
    
    // MARK: - Base Tasks
    
    /// Load all base tasks from persistent storage
    func loadBaseTasks() -> [BaseTask] {
        guard let data = UserDefaults.standard.data(forKey: baseTasksKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([BaseTask].self, from: data)
        } catch {
            print("Error decoding base tasks: \(error)")
            return []
        }
    }
    
    /// Save all base tasks to persistent storage
    func saveBaseTasks(_ tasks: [BaseTask]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tasks)
            UserDefaults.standard.set(data, forKey: baseTasksKey)
        } catch {
            print("Error encoding base tasks: \(error)")
        }
    }
    
    /// Save a single base task
    func saveBaseTask(_ task: BaseTask) {
        var tasks = loadBaseTasks()
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        saveBaseTasks(tasks)
    }
    
    /// Delete a base task
    func deleteBaseTask(withId id: UUID) {
        var tasks = loadBaseTasks()
        tasks.removeAll(where: { $0.id == id })
        saveBaseTasks(tasks)
    }
    
    // MARK: - Completed Activities
    
    /// Load all completed activities from persistent storage
    func loadCompletedActivities() -> [CompletedActivity] {
        guard let data = UserDefaults.standard.data(forKey: completedActivitiesKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([CompletedActivity].self, from: data)
        } catch {
            print("Error decoding completed activities: \(error)")
            return []
        }
    }
    
    /// Save all completed activities to persistent storage
    func saveCompletedActivities(_ activities: [CompletedActivity]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(activities)
            UserDefaults.standard.set(data, forKey: completedActivitiesKey)
        } catch {
            print("Error encoding completed activities: \(error)")
        }
    }
    
    /// Save a single completed activity
    func saveCompletedActivity(_ activity: CompletedActivity) {
        var activities = loadCompletedActivities()
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
        } else {
            activities.append(activity)
        }
        saveCompletedActivities(activities)
    }
    
    // MARK: - Initialization
    
    /// Initialize with sample data if no data exists
    func initializeWithSampleDataIfNeeded() {
        let activities = loadActivities()
        let baseTasks = loadBaseTasks()
        
        if activities.isEmpty {
            saveActivities(Activity.samples)
        }
        
        if baseTasks.isEmpty {
            saveBaseTasks(BaseTask.samples)
        }
    }
}

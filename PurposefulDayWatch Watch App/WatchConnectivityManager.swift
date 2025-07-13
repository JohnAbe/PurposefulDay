//
//  WatchConnectivityManager.swift
//  PurposefulDayWatch Watch App
//
//  Created by John Abraham on 6/29/25.
//

import Foundation
import WatchConnectivity

/// Message types for Watch connectivity
enum WatchMessage: String {
    case startActivity = "startActivity"
    case pauseActivity = "pauseActivity"
    case resumeActivity = "resumeActivity"
    case skipTask = "skipTask"
    case extendTime = "extendTime"
    case activityUpdate = "activityUpdate"
    case activityList = "activityList"
    case activityCompleted = "activityCompleted"
    case navigateToList = "navigateToList"
}

/// Manager for handling communication between Apple Watch and iPhone
class WatchConnectivityManager: NSObject, ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance for easy access throughout the app
    static let shared = WatchConnectivityManager()
    
    // MARK: - Properties
    
    /// The session for communication
    private let session = WCSession.default
    
    /// Whether the device supports Watch connectivity
    @Published var isSupported = false
    
    /// Whether the iPhone is reachable
    @Published var isReachable = false
    
    /// Callback for receiving activity updates
    var activityUpdateHandler: ((Activity, Int) -> Void)?
    
    /// Callback for receiving activity control commands
    var activityControlHandler: ((WatchMessage, [String: Any]?) -> Void)?
    
    /// Callback for receiving activity list
    var activityListHandler: (([Activity]) -> Void)?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            isSupported = true
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send Methods
    
    /// Send a control command to the iPhone
    /// - Parameters:
    ///   - command: The command to send
    ///   - data: Optional additional data
    func sendCommand(_ command: WatchMessage, data: [String: Any]? = nil) {
        guard session.activationState == .activated else { 
            print("Session not activated - cannot send command")
            return 
        }
        
        var message: [String: Any] = [command.rawValue: true]
        
        if let data = data {
            message.merge(data) { (_, new) in new }
        }
        
        if session.isReachable {
            // Use sendMessage for immediate delivery when reachable
            session.sendMessage(message, replyHandler: { reply in
                // Handle any reply if needed
                print("Command \(command.rawValue) acknowledged by iPhone")
            }, errorHandler: { error in
                print("Error sending command \(command.rawValue): \(error.localizedDescription)")
                
                // If sending fails, try to transfer user info as a fallback
                self.session.transferUserInfo(message)
                print("Command \(command.rawValue) queued via user info after failed message")
            })
        } else {
            // If not reachable, use multiple delivery methods to ensure the command gets through
            print("iPhone is not reachable - command \(command.rawValue) will be queued")
            
            // Use transferUserInfo for reliable delivery when the iPhone becomes available
            session.transferUserInfo(message)
            
            // Also try to update application context as a backup delivery method
            do {
                try session.updateApplicationContext(message)
            } catch {
                print("Failed to update application context: \(error.localizedDescription)")
            }
            
            // Retry the command after a delay if the iPhone is still not reachable
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !self.session.isReachable {
                    print("iPhone still not reachable - retrying command \(command.rawValue)")
                    self.session.transferUserInfo(message)
                }
            }
        }
    }
    
    /// Request the activity list from the iPhone
    func requestActivityList() {
        print("Requesting activity list from iPhone")
        sendCommand(.activityList)
    }
    
    /// Start an activity on the iPhone
    /// - Parameter activityId: The ID of the activity to start
    func startActivity(activityId: UUID) {
        print("Attempting to start activity: \(activityId)")
        sendCommand(.startActivity, data: ["activityId": activityId.uuidString])
    }
    
    /// Pause the current activity
    func pauseActivity() {
        print("Attempting to pause activity")
        sendCommand(.pauseActivity)
    }
    
    /// Resume the current activity
    func resumeActivity() {
        print("Attempting to resume activity")
        sendCommand(.resumeActivity)
    }
    
    /// Skip to the next task
    func skipTask() {
        print("Attempting to skip to next task")
        sendCommand(.skipTask)
    }
    
    /// Extend the time for the current task
    /// - Parameter seconds: The number of seconds to add
    func extendTime(by seconds: Int = 10) {
        print("Attempting to extend time by \(seconds) seconds")
        sendCommand(.extendTime, data: ["seconds": seconds])
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    /// Called when the session has been activated
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCSession activation failed with error: \(error.localizedDescription)")
                return
            }
            
            self.isReachable = session.isReachable
            
            print("WCSession activated with state: \(activationState.rawValue)")
            print("iPhone reachable: \(session.isReachable)")
            
            if !session.isReachable {
                print("iPhone is not reachable. Make sure the PurposefulDay app is running on your iPhone.")
                
                // Set up a timer to periodically check reachability and request data when available
                self.setupReachabilityTimer()
            } else {
                // Request activity list when session is activated and iPhone is reachable
                self.requestActivityList()
            }
        }
    }
    
    /// Set up a timer to periodically check reachability and request data when available
    private func setupReachabilityTimer() {
        // Create a timer that fires every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Check if the iPhone is now reachable
            if self.session.isReachable && !self.isReachable {
                print("iPhone is now reachable - updating state and requesting data")
                self.isReachable = true
                
                // Request activity list when iPhone becomes reachable
                self.requestActivityList()
            } else if !self.session.isReachable && self.isReachable {
                // Update the reachable state if it changed
                self.isReachable = false
                print("iPhone is no longer reachable")
            }
        }
    }
    
    /// Called when the session reachability changes
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    /// Called when a message is received
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message)
    }
    
    /// Called when application context is received
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleMessage(applicationContext)
    }
    
    /// Called when user info is received
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleMessage(userInfo)
    }
    
    /// Handle incoming messages
    private func handleMessage(_ message: [String: Any]) {
        DispatchQueue.main.async {
            // Log received message for debugging
            print("Received message from iPhone: \(message.keys.joined(separator: ", "))")
            
            // Handle activity update
            if let updateData = message[WatchMessage.activityUpdate.rawValue] as? [String: Any],
               let activityData = updateData["activity"] as? Data,
               let currentTaskIndex = updateData["currentTaskIndex"] as? Int {
                do {
                    let decoder = JSONDecoder()
                    let activity = try decoder.decode(Activity.self, from: activityData)
                    print("Decoded activity update from iPhone: \(activity.name), task \(currentTaskIndex + 1)/\(activity.tasks.count)")
                    
                    // Check if the current task is paused by examining its progress
                    let isPaused = currentTaskIndex < activity.tasks.count && 
                                  activity.tasks[currentTaskIndex].progress > 0 && 
                                  !activity.tasks[currentTaskIndex].isCompleted
                    
                    print("Activity state: \(isPaused ? "paused" : "running")")
                    
                    self.activityUpdateHandler?(activity, currentTaskIndex)
                } catch {
                    print("Error decoding activity: \(error.localizedDescription)")
                }
            }
            
            // Handle activity list
            if let activitiesData = message[WatchMessage.activityList.rawValue] as? Data {
                do {
                    let decoder = JSONDecoder()
                    let activities = try decoder.decode([Activity].self, from: activitiesData)
                    print("Decoded activity list from iPhone: \(activities.count) activities")
                    self.activityListHandler?(activities)
                } catch {
                    print("Error decoding activities: \(error.localizedDescription)")
                }
            }
            
            // Handle control commands
            for command in WatchMessage.allCases {
                if message[command.rawValue] != nil {
                    print("Received command from iPhone: \(command.rawValue)")
                    self.activityControlHandler?(command, message)
                    break
                }
            }
        }
    }
}

// MARK: - WatchMessage Extension
extension WatchMessage: CaseIterable {
    static var allCases: [WatchMessage] {
        return [.startActivity, .pauseActivity, .resumeActivity, .skipTask, .extendTime, .activityUpdate, .activityList, .activityCompleted, .navigateToList]
    }
}

// MARK: - Activity Struct (Placeholder)
struct Activity: Codable, Identifiable {
    var id: UUID
    var name: String
    var tasks: [Task]
    
    // Add any other properties needed for your app
}

// MARK: - Task Struct (Placeholder)
struct Task: Codable, Identifiable {
    var id: UUID
    var name: String
    var duration: TimeInterval
    var progress: Int = 0
    var isCompleted: Bool = false
    
    // Add any other properties needed for your app
}

//
//  WatchConnectivityManager.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
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

/// Manager for handling communication between iPhone and Apple Watch
class WatchConnectivityManager: NSObject, ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance for easy access throughout the app
    static let shared = WatchConnectivityManager()
    
    // MARK: - Properties
    
    /// The session for communication
    private let session = WCSession.default
    
    /// Whether the device supports Watch connectivity
    @Published var isSupported = false
    
    /// Whether the Watch is paired
    @Published var isPaired = false
    
    /// Whether the Watch app is installed
    @Published var isInstalled = false
    
    /// Whether the Watch is reachable
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
    
    /// Send the current activity state to the Watch
    /// - Parameters:
    ///   - activity: The activity being run
    ///   - currentTaskIndex: The index of the current task
    func sendActivityUpdate(activity: Activity, currentTaskIndex: Int) {
        guard session.activationState == .activated else { 
            print("Session not activated - cannot send activity update")
            return 
        }
        
        do {
            let encoder = JSONEncoder()
            let activityData = try encoder.encode(activity)
            
            let message: [String: Any] = [
                WatchMessage.activityUpdate.rawValue: [
                    "activity": activityData,
                    "currentTaskIndex": currentTaskIndex
                ]
            ]
            
            if session.isReachable {
                // Use sendMessage for immediate delivery when reachable
                session.sendMessage(message, replyHandler: { reply in
                    // Handle any reply if needed
                    print("Activity update acknowledged by Watch")
                }, errorHandler: { error in
                    print("Error sending activity update: \(error.localizedDescription)")
                    
                    // If sending fails, try to update application context as a fallback
                    do {
                        try self.session.updateApplicationContext(message)
                        print("Activity update queued via application context after failed message")
                    } catch {
                        print("Failed to queue activity update: \(error.localizedDescription)")
                    }
                })
            } else {
                // If not reachable, update app context which will be delivered when available
                print("Watch is not reachable - activity update will be queued")
                try session.updateApplicationContext(message)
                
                // Also queue as user info as a backup delivery method
                session.transferUserInfo(message)
            }
        } catch {
            print("Error encoding activity: \(error.localizedDescription)")
        }
    }
    
    /// Send the list of activities to the Watch
    /// - Parameter activities: The list of activities
    func sendActivityList(_ activities: [Activity]) {
        guard session.activationState == .activated else { 
            print("Session not activated - cannot send activity list")
            return 
        }
        
        do {
            let encoder = JSONEncoder()
            let activitiesData = try encoder.encode(activities)
            
            let message: [String: Any] = [
                WatchMessage.activityList.rawValue: activitiesData
            ]
            
            if session.isReachable {
                session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                    print("Error sending activity list: \(error.localizedDescription)")
                })
            } else {
                // If not reachable, transfer user info which will be delivered when available
                print("Watch is not reachable - activity list will be queued")
                session.transferUserInfo(message)
            }
        } catch {
            print("Error encoding activities: \(error.localizedDescription)")
        }
    }
    
    /// Send a control command to the counterpart device
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
                print("Command \(command.rawValue) acknowledged by Watch")
            }, errorHandler: { error in
                print("Error sending command \(command.rawValue): \(error.localizedDescription)")
                
                // If sending fails, try to transfer user info as a fallback
                self.session.transferUserInfo(message)
                print("Command \(command.rawValue) queued via user info after failed message")
            })
        } else {
            // If not reachable, use multiple delivery methods to ensure the command gets through
            print("Watch is not reachable - command \(command.rawValue) will be queued")
            
            // Use transferUserInfo for reliable delivery when the watch becomes available
            session.transferUserInfo(message)
            
            // Also try to update application context as a backup delivery method
            do {
                try session.updateApplicationContext(message)
            } catch {
                print("Failed to update application context: \(error.localizedDescription)")
            }
        }
    }
    
    /// Request the activity list from the counterpart device
    func requestActivityList() {
        sendCommand(.activityList)
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
            
            self.isPaired = session.isPaired
            self.isInstalled = session.isWatchAppInstalled
            
            if !session.isPaired {
                print("Apple Watch is not paired with this iPhone")
            }
            
            if !session.isWatchAppInstalled {
                print("PurposefulDay Watch app is not installed on the paired Apple Watch")
                print("Please install the Watch app from the Watch app on your iPhone")
            }
            
            print("WCSession activated with state: \(activationState.rawValue)")
            print("Watch paired: \(session.isPaired), Watch app installed: \(session.isWatchAppInstalled), Watch reachable: \(session.isReachable)")
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
            print("Received message from Watch: \(message.keys.joined(separator: ", "))")
            
            // Handle activity update
            if let updateData = message[WatchMessage.activityUpdate.rawValue] as? [String: Any],
               let activityData = updateData["activity"] as? Data,
               let currentTaskIndex = updateData["currentTaskIndex"] as? Int {
                do {
                    let decoder = JSONDecoder()
                    let activity = try decoder.decode(Activity.self, from: activityData)
                    print("Decoded activity update from Watch: \(activity.name), task \(currentTaskIndex + 1)/\(activity.tasks.count)")
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
                    print("Decoded activity list from Watch: \(activities.count) activities")
                    self.activityListHandler?(activities)
                } catch {
                    print("Error decoding activities: \(error.localizedDescription)")
                }
            }
            
            // Handle control commands
            for command in WatchMessage.allCases {
                if message[command.rawValue] != nil {
                    print("Received command from Watch: \(command.rawValue)")
                    self.activityControlHandler?(command, message)
                    break
                }
            }
        }
    }
    
    // Required by WCSessionDelegate but not used on watchOS
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive (iOS only)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation (iOS only)
        // Activate a new session after the previous one is deactivated
        session.activate()
    }
    #endif
}

// MARK: - WatchMessage Extension
extension WatchMessage: CaseIterable {
    static var allCases: [WatchMessage] {
        return [.startActivity, .pauseActivity, .resumeActivity, .skipTask, .extendTime, .activityUpdate, .activityList, .activityCompleted, .navigateToList]
    }
}

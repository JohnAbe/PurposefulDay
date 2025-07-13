//
//  ExtensionDelegate.swift
//  PurposefulDayWatch Watch App
//
//  Created by John Abraham on 6/29/25.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        print("Watch app extension did finish launching")
        
        // Initialize Watch connectivity
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = WatchConnectivityManager.shared
            session.activate()
            print("Watch connectivity session activated")
        } else {
            print("Watch connectivity is not supported on this device")
        }
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.
        print("Watch app extension did become active")
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        // or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        print("Watch app extension will resign active")
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks.
        // Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Process the background task
            
            // Be sure to complete the task when finished
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}

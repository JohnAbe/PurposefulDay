//
//  PurposefulDayApp.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import SwiftUI
import WatchConnectivity

@main
struct PurposefulDayApp: App {
    // MARK: - Properties
    
    /// App delegate for handling system events
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// The main view model for the activity list
    @StateObject private var activityListViewModel = ActivityListViewModel()
    
    /// The watch connectivity manager
    @StateObject private var watchConnectivityManager = WatchConnectivityManager.shared
    
    // MARK: - Initialization
    init() {
        // Initialize sample data if needed
        DataService.shared.initializeWithSampleDataIfNeeded()
        
        // Set up appearance
        configureAppearance()
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(activityListViewModel)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Configure the app's appearance
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Request notification permissions
        requestNotificationPermissions()
        
        // Set self as delegate for notification center
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - Notifications
    
    /// Request permission to send notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// This method is called when a notification is delivered to a foreground app
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    /// This method is called when user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Handle the notification action if needed
        let identifier = response.notification.request.identifier
        print("User tapped on notification: \(identifier)")
        
        // Complete the handling
        completionHandler()
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ActivityListViewModel())
}

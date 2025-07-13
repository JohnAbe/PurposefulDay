//
//  ContentView.swift
//  PurposefulDayWatch Watch App
//
//  Created by John Abraham on 6/22/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared
    @State private var isActivityRunning = false
    
    // Audio service for haptic feedback
    private let audioService = WatchAudioService.shared
    
    var body: some View {
        NavigationView {
            if isActivityRunning {
                WatchActivityRunnerView()
            } else {
                WatchActivityListView()
            }
        }
        .onAppear {
            // Set up a handler to detect when an activity is started
            connectivityManager.activityUpdateHandler = { _, _ in
                isActivityRunning = true
            }
            
            // Set up a handler to detect when an activity is completed or navigation is requested
            connectivityManager.activityControlHandler = { command, _ in
                switch command {
                case .activityCompleted:
                    isActivityRunning = false
                    audioService.playHaptic(for: .activityComplete)
                case .navigateToList:
                    isActivityRunning = false
                    audioService.clickHaptic()
                default:
                    break
                }
            }
            
            // Listen for navigation notifications
            NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToList"), object: nil, queue: .main) { _ in
                isActivityRunning = false
            }
        }
    }
}

#Preview {
    ContentView()
}

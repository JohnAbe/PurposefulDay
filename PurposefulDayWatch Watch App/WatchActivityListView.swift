//
//  WatchActivityListView.swift
//  PurposefulDayWatch Watch App
//
//  Created by John Abraham on 6/29/25.
//

import SwiftUI

struct WatchActivityListView: View {
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared
    @State private var activities: [Activity] = []
    @State private var isRefreshing: Bool = false
    
    // Audio service for haptic feedback
    private let audioService = WatchAudioService.shared
    
    var body: some View {
        List {
            if activities.isEmpty {
                VStack {
                    Text("No activities available")
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        refreshActivities()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .padding(.top, 8)
                }
            } else {
                ForEach(activities) { activity in
                    Button(action: {
                        connectivityManager.startActivity(activityId: activity.id)
                        audioService.clickHaptic()
                    }) {
                        VStack(alignment: .leading) {
                            Text(activity.name)
                                .fontWeight(.medium)
                            
                            if !activity.tasks.isEmpty {
                                Text("\(activity.tasks.count) tasks")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Button(action: {
                    refreshActivities()
                }) {
                    Label("Refresh Activities", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Activities")
        .refreshable {
            refreshActivities()
        }
        .onAppear {
            // Set up the activity list handler
            connectivityManager.activityListHandler = { receivedActivities in
                self.activities = receivedActivities
                self.isRefreshing = false
                
                // Provide haptic feedback when activities are loaded
                if !receivedActivities.isEmpty {
                    self.audioService.notificationHaptic()
                }
            }
            
            // Request the activity list from the iPhone
            refreshActivities()
        }
    }
    
    private func refreshActivities() {
        isRefreshing = true
        connectivityManager.requestActivityList()
        audioService.clickHaptic()
    }
}

#Preview {
    WatchActivityListView()
}

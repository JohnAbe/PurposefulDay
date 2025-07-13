//
//  PurposefulDayWatchApp.swift
//  PurposefulDayWatch Watch App
//
//  Created by John Abraham on 6/22/25.
//

import SwiftUI
import WatchKit

@main
struct PurposefulDayWatchApp: App {
    // MARK: - Properties
    
    /// The extension delegate
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate
    
    /// The watch connectivity manager
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("PurposefulDay Watch app appeared")
                }
        }
    }
}

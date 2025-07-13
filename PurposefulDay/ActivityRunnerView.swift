//
//  ActivityRunnerView.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import SwiftUI

/// View for running an activity
struct ActivityRunnerView: View {
    // MARK: - Environment
    
    /// Environment value for dismissing the view
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    /// The view model for running the activity
    @StateObject private var viewModel: ActivityRunnerViewModel
    
    /// Whether the confirmation dialog for stopping is shown
    @State private var showStopConfirmation = false
    
    // MARK: - Initialization
    
    /// Initialize with an activity and completion callback
    /// - Parameters:
    ///   - activity: The activity to run
    ///   - onComplete: Callback when the activity is completed
    init(activity: Activity, onComplete: @escaping (CompletedActivity) -> Void) {
        _viewModel = StateObject(wrappedValue: ActivityRunnerViewModel(activity: activity, onComplete: onComplete))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Content
            if viewModel.showCountdown {
                // Countdown view
                countdownView
            } else if viewModel.isCompleted {
                // Completion view
                completionView
            } else {
                // Main runner view
                VStack(spacing: 30) {
                    // Activity name
                    Text(viewModel.activity.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Current task
                    if let task = viewModel.currentTask {
                        // Task name
                        Text(task.name)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Task type and progress
                        if task.durationType == .timed {
                            // Timer display
                            ZStack {
                                // Progress circle
                                Circle()
                                    .stroke(lineWidth: 20)
                                    .opacity(0.3)
                                    .foregroundColor(.gray)
                                
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(viewModel.progressPercentage() / 100.0))
                                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                                    .foregroundColor(.blue)
                                    .rotationEffect(Angle(degrees: 270.0))
                                
                                // Time remaining
                                Text(viewModel.formattedTimeRemaining())
                                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 250, height: 250)
                            .padding()
                            
                            // Extend time button
                            Button {
                                viewModel.extendTime(by: 10)
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add 10s")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.6))
                                .cornerRadius(20)
                            }
                            .padding(.top, 10)
                        } else {
                            // Count display
                            VStack(spacing: 20) {
                                // Progress text
                                Text("\(viewModel.currentProgress) / \(task.duration)")
                                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                // Progress bar
                                ProgressView(value: Double(viewModel.currentProgress), total: Double(task.duration))
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                                    .frame(width: 250)
                                
                                // Increment/decrement buttons
                                HStack(spacing: 40) {
                                    Button {
                                        viewModel.decrementProgress()
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Button {
                                        viewModel.incrementProgress()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(.top, 20)
                            }
                            .frame(width: 250, height: 250)
                            .padding()
                        }
                        
                        // Next task preview
                        if let nextTask = viewModel.nextTask {
                            VStack(spacing: 5) {
                                Text("Next:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text(nextTask.name)
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(nextTask.formattedDuration())
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 40) {
                        // Stop button
                        Button {
                            showStopConfirmation = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        
                        // Play/pause button
                        Button {
                            if viewModel.isPaused {
                                viewModel.resumeActivity()
                            } else {
                                viewModel.pauseActivity()
                            }
                        } label: {
                            Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                        }
                        
                        // Skip button
                        Button {
                            viewModel.completeCurrentTask()
                        } label: {
                            Image(systemName: "forward.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .onAppear {
            // Start the activity when the view appears
            viewModel.startActivity()
        }
        .onDisappear {
            // Clean up resources when the view disappears
            viewModel.cleanup()
        }
        .confirmationDialog(
            "Stop Activity?",
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Stop and Exit", role: .destructive) {
                viewModel.stopActivity()
                dismiss()
            }
            
            Button("Cancel", role: .cancel) {
                showStopConfirmation = false
            }
        } message: {
            Text("Are you sure you want to stop this activity? Progress will not be saved.")
        }
    }
    
    // MARK: - Countdown View
    
    /// View for the countdown before starting the activity
    private var countdownView: some View {
        VStack {
            Spacer()
            
            Text("Starting in")
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(viewModel.countdownValue)")
                .font(.system(size: 120, weight: .bold))
                .foregroundColor(.white)
                .padding()
            
            Text("Get ready...")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    // MARK: - Completion View
    
    /// View for when the activity is completed
    private var completionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Completion icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            // Completion text
            Text("Activity Completed!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Activity name
            Text(viewModel.activity.name)
                .font(.title2)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            // Done button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding()
                    .frame(width: 200)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 40)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    ActivityRunnerView(activity: Activity.samples[0]) { _ in }
}

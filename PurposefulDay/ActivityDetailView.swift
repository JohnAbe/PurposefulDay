//
//  ActivityDetailView.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import SwiftUI

/// View for displaying and editing the details of an activity
struct ActivityDetailView: View {
    // MARK: - Environment
    
    /// The activity list view model (for accessing base tasks)
    @EnvironmentObject var activityListViewModel: ActivityListViewModel
    
    // MARK: - State
    
    /// The view model for this activity
    @StateObject private var viewModel: ActivityDetailViewModel
    
    /// Whether the add task sheet is presented
    @State private var isAddingTask = false
    
    /// Whether the activity is being run
    @State private var isRunningActivity = false
    
    /// Whether the edit mode is active
    @State private var editMode: EditMode = .inactive
    
    /// The name of the new task
    @State private var newTaskName = ""
    
    /// The duration type of the new task
    @State private var newTaskDurationType = TaskDurationType.timed
    
    /// The duration of the new task
    @State private var newTaskDuration = 60
    
    /// Whether to use a base task for the new task
    @State private var useBaseTask = false
    
    /// The selected base task for the new task
    @State private var selectedBaseTaskId: UUID?
    
    // MARK: - Initialization
    
    /// Initialize with an activity and update callback
    /// - Parameters:
    ///   - activity: The activity to display and edit
    ///   - onUpdate: Callback when the activity is updated
    init(activity: Activity, onUpdate: @escaping (Activity) -> Void) {
        _viewModel = StateObject(wrappedValue: ActivityDetailViewModel(activity: activity, onUpdate: onUpdate))
    }
    
    // MARK: - Body
    var body: some View {
        List {
            // Tasks Section
            Section(header: Text("Tasks")) {
                if viewModel.activity.tasks.isEmpty {
                    Text("No tasks yet. Tap + to add one.")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.activity.tasks) { task in
                        TaskRow(task: task, onToggleCompletion: {
                            viewModel.toggleTaskCompletion(taskId: task.id)
                        })
                    }
                    .onDelete(perform: viewModel.deleteTasks)
                    .onMove(perform: viewModel.moveTasks)
                }
            }
            
            // Info Section
            if !viewModel.activity.tasks.isEmpty {
                Section(header: Text("Info")) {
                    // Total duration
                    HStack {
                        Label("Total Duration", systemImage: "clock")
                        Spacer()
                        Text(viewModel.activity.formattedTotalDuration())
                            .foregroundColor(.secondary)
                    }
                    
                    // Task counts
                    let taskCounts = viewModel.activity.taskCountByType()
                    HStack {
                        Label("Tasks", systemImage: "list.bullet")
                        Spacer()
                        Text("\(taskCounts.timed) timed, \(taskCounts.count) count")
                            .foregroundColor(.secondary)
                    }
                    
                    // Last completed
                    if let lastCompleted = viewModel.activity.lastCompletedAt {
                        HStack {
                            Label("Last Completed", systemImage: "checkmark.circle")
                            Spacer()
                            Text("\(lastCompleted, formatter: dateFormatter)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Actions Section
            if !viewModel.activity.tasks.isEmpty {
                Section {
                    Button {
                        isRunningActivity = true
                    } label: {
                        Label("Start Activity", systemImage: "play.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.blue)
                    }
                    
                    if viewModel.areAllTasksCompleted() {
                        Button {
                            viewModel.resetAllTasks()
                        } label: {
                            Label("Reset All Tasks", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(viewModel.activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isAddingTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $isAddingTask) {
            NavigationView {
                Form {
                    // Task Source Section
                    if !activityListViewModel.baseTasks.isEmpty {
                        Section {
                            Toggle("Use Task from Library", isOn: $useBaseTask)
                        }
                    }
                    
                    // Base Task Selection
                    if useBaseTask && !activityListViewModel.baseTasks.isEmpty {
                        Section(header: Text("Select Task")) {
                            ForEach(activityListViewModel.baseTasks) { task in
                                Button {
                                    selectedBaseTaskId = task.id
                                    newTaskName = task.name
                                    newTaskDurationType = task.defaultDurationType
                                    newTaskDuration = task.defaultDuration
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(task.name)
                                                .foregroundColor(.primary)
                                            
                                            HStack {
                                                Text(task.defaultDurationType == .timed ? "Timed" : "Count")
                                                    .foregroundColor(.secondary)
                                                
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                
                                                if task.defaultDurationType == .timed {
                                                    let minutes = task.defaultDuration / 60
                                                    let seconds = task.defaultDuration % 60
                                                    Text("\(minutes)m \(seconds > 0 ? "\(seconds)s" : "")")
                                                        .foregroundColor(.secondary)
                                                } else {
                                                    Text("\(task.defaultDuration) reps")
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .font(.caption)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedBaseTaskId == task.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Task Details Section
                    Section(header: Text("Task Details")) {
                        TextField("Task Name", text: $newTaskName)
                            .autocapitalization(.words)
                            .disabled(useBaseTask && selectedBaseTaskId != nil)
                        
                        Picker("Duration Type", selection: $newTaskDurationType) {
                            Text("Timed").tag(TaskDurationType.timed)
                            Text("Count").tag(TaskDurationType.count)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .disabled(useBaseTask && selectedBaseTaskId != nil)
                        
                        if newTaskDurationType == .timed {
                            VStack(alignment: .leading) {
                                Text("Duration: \(formattedDuration(newTaskDuration))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: Binding(
                                    get: { Double(newTaskDuration) },
                                    set: { newTaskDuration = Int($0) }
                                ), in: 5...3600, step: 5)
                            }
                        } else {
                            Stepper("Count: \(newTaskDuration)", value: $newTaskDuration, in: 1...1000)
                        }
                    }
                }
                .navigationTitle("Add Task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetNewTaskFields()
                            isAddingTask = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            if !newTaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                if useBaseTask, let baseTaskId = selectedBaseTaskId,
                                   let baseTask = activityListViewModel.baseTasks.first(where: { $0.id == baseTaskId }) {
                                    // Create task from base task
                                    var task = ActivityTask(from: baseTask)
                                    // Allow customization of duration
                                    task.duration = newTaskDuration
                                    viewModel.addTask(task)
                                } else {
                                    // Create task from scratch
                                    let task = ActivityTask(
                                        name: newTaskName,
                                        durationType: newTaskDurationType,
                                        duration: newTaskDuration
                                    )
                                    viewModel.addTask(task)
                                }
                                
                                resetNewTaskFields()
                                isAddingTask = false
                            }
                        }
                        .disabled(newTaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isRunningActivity) {
            ActivityRunnerView(activity: viewModel.activity) { completedActivity in
                // Handle completed activity
                activityListViewModel.addCompletedActivity(completedActivity)
                
                // Update the activity
                var updatedActivity = viewModel.activity
                updatedActivity.isCompleted = true
                updatedActivity.lastCompletedAt = completedActivity.completedAt
                viewModel.activity = updatedActivity
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset the new task fields
    private func resetNewTaskFields() {
        newTaskName = ""
        newTaskDurationType = .timed
        newTaskDuration = 60
        useBaseTask = false
        selectedBaseTaskId = nil
    }
    
    /// Format the duration for display
    /// - Parameter seconds: The duration in seconds
    /// - Returns: Formatted duration string
    private func formattedDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return remainingSeconds > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(minutes) minutes"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours) hours"
        }
    }
    
    // MARK: - Formatters
    
    /// Date formatter for the last completed date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Task Row
/// Row for displaying a task in the activity detail view
struct TaskRow: View {
    // MARK: - Properties
    
    /// The task to display
    let task: ActivityTask
    
    /// Callback when the completion status is toggled
    let onToggleCompletion: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack {
            // Completion checkbox
            Button {
                onToggleCompletion()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack {
                    // Task type
                    Text(task.durationType == .timed ? "Timed" : "Count")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    // Duration
                    Text(task.formattedDuration())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Progress (if any)
                    if task.progress > 0 && !task.isCompleted {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(task.formattedProgress())
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ActivityDetailView(activity: Activity.samples[0]) { _ in }
            .environmentObject(ActivityListViewModel())
    }
}

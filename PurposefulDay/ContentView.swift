//
//  ContentView.swift
//  PurposefulDay
//
//  Created by John Abraham on 6/22/25.
//

import SwiftUI

/// The main content view for the app
struct ContentView: View {
    // MARK: - Environment
    
    /// The activity list view model
    @EnvironmentObject var activityListViewModel: ActivityListViewModel
    
    // MARK: - State
    
    /// The selected tab
    @State private var selectedTab = 0
    
    /// Whether an activity is being run
    @State private var isRunningActivity = false
    
    /// The activity being run
    @State private var runningActivity: Activity?
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Activities Tab
            NavigationView {
                ActivityListView()
                    .navigationTitle("Activities")
            }
            .tabItem {
                Label("Activities", systemImage: "list.bullet")
            }
            .tag(0)
            
            // History Tab
            NavigationView {
                HistoryView()
                    .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }
            .tag(1)
            
            // Task Library Tab
            NavigationView {
                TaskLibraryView()
                    .navigationTitle("Task Library")
            }
            .tabItem {
                Label("Library", systemImage: "square.stack")
            }
            .tag(2)
        }
        .onAppear {
            // Load data when the app appears
            activityListViewModel.loadData()
            
            // Listen for StartActivity notifications from the watch
            NotificationCenter.default.addObserver(forName: NSNotification.Name("StartActivity"), object: nil, queue: .main) { notification in
                if let userInfo = notification.userInfo,
                   let activityId = userInfo["activityId"] as? UUID,
                   let activity = activityListViewModel.activities.first(where: { $0.id == activityId }) {
                    // Start the activity
                    runningActivity = activity
                    isRunningActivity = true
                }
            }
        }
        .fullScreenCover(isPresented: $isRunningActivity) {
            if let activity = runningActivity {
                ActivityRunnerView(activity: activity) { completedActivity in
                    // Handle completed activity
                    activityListViewModel.addCompletedActivity(completedActivity)
                    
                    // Update the activity
                    var updatedActivity = activity
                    updatedActivity.isCompleted = true
                    updatedActivity.lastCompletedAt = completedActivity.completedAt
                    activityListViewModel.updateActivity(updatedActivity)
                    
                    // Reset state
                    runningActivity = nil
                }
            }
        }
    }
}

// MARK: - Activity List View
/// View for displaying the list of activities
struct ActivityListView: View {
    // MARK: - Environment
    
    /// The activity list view model
    @EnvironmentObject var viewModel: ActivityListViewModel
    
    // MARK: - State
    
    /// Whether the add activity sheet is presented
    @State private var isAddingActivity = false
    
    /// The name of the new activity
    @State private var newActivityName = ""
    
    // MARK: - Body
    var body: some View {
        List {
            // Activities Section
            Section {
                if viewModel.activities.isEmpty {
                    Text("No activities yet. Tap + to create one.")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.activities) { activity in
                        NavigationLink(destination: ActivityDetailView(activity: activity) { updatedActivity in
                            viewModel.updateActivity(updatedActivity)
                        }) {
                            ActivityRow(activity: activity)
                        }
                    }
                    .onDelete(perform: viewModel.deleteActivity)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            viewModel.loadData()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isAddingActivity = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingActivity) {
            NavigationView {
                Form {
                    Section(header: Text("Activity Details")) {
                        TextField("Activity Name", text: $newActivityName)
                            .autocapitalization(.words)
                    }
                }
                .navigationTitle("New Activity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            newActivityName = ""
                            isAddingActivity = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            if !newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                let activity = viewModel.createActivity(name: newActivityName)
                                newActivityName = ""
                                isAddingActivity = false
                            }
                        }
                        .disabled(newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Activity Row
/// Row for displaying an activity in the list
struct ActivityRow: View {
    // MARK: - Properties
    
    /// The activity to display
    let activity: Activity
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(activity.name)
                    .font(.headline)
                
                Spacer()
                
                if activity.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                // Task count
                let taskCounts = activity.taskCountByType()
                Text("\(activity.tasks.count) tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if taskCounts.timed > 0 {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(activity.formattedTotalDuration())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Last completed date
                if let lastCompleted = activity.lastCompletedAt {
                    Text("Last: \(lastCompleted, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Formatters
    
    /// Date formatter for the last completed date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

// MARK: - History View
/// View for displaying the history of completed activities
struct HistoryView: View {
    // MARK: - Environment
    
    /// The activity list view model
    @EnvironmentObject var viewModel: ActivityListViewModel
    
    // MARK: - State
    
    /// The selected time range
    @State private var selectedTimeRange = TimeRange.week
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Completed activities list
            List {
                let completedActivities = filteredCompletedActivities()
                
                if completedActivities.isEmpty {
                    Text("No completed activities in this time range.")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(completedActivities) { activity in
                        NavigationLink(destination: CompletedActivityDetailView(activity: activity)) {
                            CompletedActivityRow(activity: activity)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Filter completed activities based on the selected time range
    /// - Returns: Filtered completed activities
    private func filteredCompletedActivities() -> [CompletedActivity] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .day:
            guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) else {
                return []
            }
            return viewModel.getCompletedActivities(from: startOfDay, to: now)
            
        case .week:
            guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
                return []
            }
            return viewModel.getCompletedActivities(from: oneWeekAgo, to: now)
            
        case .month:
            guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) else {
                return []
            }
            return viewModel.getCompletedActivities(from: oneMonthAgo, to: now)
            
        case .all:
            return viewModel.completedActivities.sorted(by: { $0.completedAt > $1.completedAt })
        }
    }
    
    // MARK: - Time Range Enum
    
    /// Time range for filtering completed activities
    enum TimeRange: String, CaseIterable {
        case day
        case week
        case month
        case all
        
        /// Display name for the time range
        var displayName: String {
            switch self {
            case .day: return "Today"
            case .week: return "Week"
            case .month: return "Month"
            case .all: return "All"
            }
        }
    }
}

// MARK: - Completed Activity Row
/// Row for displaying a completed activity in the history list
struct CompletedActivityRow: View {
    // MARK: - Properties
    
    /// The completed activity to display
    let activity: CompletedActivity
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(activity.name)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                // Task count
                Text("\(activity.tasks.count) tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(activity.formattedTotalDuration())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Completion date
                Text("\(activity.completedAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Formatters
    
    /// Date formatter for the completion date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Task Library View
/// View for displaying and managing the library of base tasks
struct TaskLibraryView: View {
    // MARK: - Environment
    
    /// The activity list view model
    @EnvironmentObject var viewModel: ActivityListViewModel
    
    // MARK: - State
    
    /// Whether the add task sheet is presented
    @State private var isAddingTask = false
    
    /// The name of the new task
    @State private var newTaskName = ""
    
    /// The duration type of the new task
    @State private var newTaskDurationType = TaskDurationType.timed
    
    /// The duration of the new task
    @State private var newTaskDuration = 60
    
    // MARK: - Body
    var body: some View {
        List {
            // Base Tasks Section
            Section {
                if viewModel.baseTasks.isEmpty {
                    Text("No tasks in library yet. Tap + to create one.")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.baseTasks) { task in
                        BaseTaskRow(task: task)
                    }
                    .onDelete(perform: viewModel.deleteBaseTask)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            viewModel.loadData()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isAddingTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingTask) {
            NavigationView {
                Form {
                    Section(header: Text("Task Details")) {
                        TextField("Task Name", text: $newTaskName)
                            .autocapitalization(.words)
                        
                        Picker("Duration Type", selection: $newTaskDurationType) {
                            Text("Timed").tag(TaskDurationType.timed)
                            Text("Count").tag(TaskDurationType.count)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
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
                .navigationTitle("New Task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetNewTaskFields()
                            isAddingTask = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            if !newTaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                let task = viewModel.createBaseTask(
                                    name: newTaskName,
                                    durationType: newTaskDurationType,
                                    duration: newTaskDuration
                                )
                                resetNewTaskFields()
                                isAddingTask = false
                            }
                        }
                        .disabled(newTaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset the new task fields
    private func resetNewTaskFields() {
        newTaskName = ""
        newTaskDurationType = .timed
        newTaskDuration = 60
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
}

// MARK: - Base Task Row
/// Row for displaying a base task in the library
struct BaseTaskRow: View {
    // MARK: - Properties
    
    /// The base task to display
    let task: BaseTask
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.name)
                .font(.headline)
            
            HStack {
                // Task type
                Text(task.defaultDurationType == .timed ? "Timed" : "Count")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Duration
                if task.defaultDurationType == .timed {
                    let minutes = task.defaultDuration / 60
                    let seconds = task.defaultDuration % 60
                    
                    if minutes > 0 {
                        Text("\(minutes)m \(seconds > 0 ? "\(seconds)s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(task.defaultDuration)s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("\(task.defaultDuration) reps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Completed Activity Detail View
/// View for displaying the details of a completed activity
struct CompletedActivityDetailView: View {
    // MARK: - Properties
    
    /// The completed activity to display
    let activity: CompletedActivity
    
    // MARK: - Body
    var body: some View {
        List {
            // Activity Info Section
            Section(header: Text("Activity Info")) {
                LabeledContent("Completed", value: activity.completedAt, format: .dateTime)
                LabeledContent("Total Duration", value: activity.formattedTotalDuration())
                LabeledContent("Tasks Completed", value: "\(activity.tasks.count)")
            }
            
            // Tasks Section
            Section(header: Text("Tasks")) {
                ForEach(activity.tasks) { task in
                    CompletedTaskRow(task: task)
                }
            }
        }
        .navigationTitle(activity.name)
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Completed Task Row
/// Row for displaying a completed task
struct CompletedTaskRow: View {
    // MARK: - Properties
    
    /// The completed task to display
    let task: CompletedTask
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.name)
                .font(.headline)
            
            HStack {
                // Task type
                Text(task.durationType == .timed ? "Timed" : "Count")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                // Planned vs actual
                if task.durationType == .timed {
                    let plannedMinutes = task.plannedDuration / 60
                    let plannedSeconds = task.plannedDuration % 60
                    let actualMinutes = task.actualDuration / 60
                    let actualSeconds = task.actualDuration % 60
                    
                    Text("Planned: \(plannedMinutes)m \(plannedSeconds > 0 ? "\(plannedSeconds)s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Actual: \(actualMinutes)m \(actualSeconds > 0 ? "\(actualSeconds)s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Target: \(task.plannedDuration)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Completed: \(task.actualDuration)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ActivityListViewModel())
}

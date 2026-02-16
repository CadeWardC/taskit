import WidgetKit
import SwiftUI

// MARK: - API Models

struct TaskItem: Codable, Identifiable {
    let id: Int
    let title: String
    let detail: String?
    let is_completed: Bool
    let priority: String?
    let list_id: Int?
    let due_date: String?
}

struct HabitItem: Codable, Identifiable {
    let id: Int
    let title: String
    let detail: String?
    let icon: String?
    let color: String?
    let target_count: Int
    let current_progress: Int
    let current_streak: Int
    let best_streak: Int
    
    var isCompleted: Bool {
        current_progress >= target_count
    }
}

struct ListItem: Codable, Identifiable {
    let id: Int
    let title: String
    let color: String?
}

// MARK: - API Service

class DirectusAPI {
    static let baseUrl = "https://api.opcw032522.uk"
    
    static func fetchTodos(userId: String) async -> [TaskItem] {
        guard let url = URL(string: "\(baseUrl)/items/todos?filter[user_id][_eq]=\(userId)") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(DirectusResponse<TaskItem>.self, from: data)
            return response.data
        } catch {
            print("Error fetching todos: \(error)")
            return []
        }
    }
    
    static func fetchHabits(userId: String) async -> [HabitItem] {
        guard let url = URL(string: "\(baseUrl)/items/habits?filter[user_id][_eq]=\(userId)") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(DirectusResponse<HabitItem>.self, from: data)
            return response.data
        } catch {
            print("Error fetching habits: \(error)")
            return []
        }
    }
    
    static func fetchLists(userId: String) async -> [ListItem] {
        guard let url = URL(string: "\(baseUrl)/items/lists?filter[user_id][_eq]=\(userId)") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(DirectusResponse<ListItem>.self, from: data)
            return response.data
        } catch {
            print("Error fetching lists: \(error)")
            return []
        }
    }
    
    static func completeTodo(id: Int) async -> Bool {
        guard let url = URL(string: "\(baseUrl)/items/todos/\(id)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["is_completed": true])
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    static func toggleHabit(id: Int, completed: Bool, currentProgress: Int, targetCount: Int) async -> Bool {
        guard let url = URL(string: "\(baseUrl)/items/habits/\(id)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let newProgress = completed ? 0 : targetCount
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["current_progress": newProgress])
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

struct DirectusResponse<T: Codable>: Codable {
    let data: [T]
}

// MARK: - Widget Configuration

enum DisplayMode: String, CaseIterable {
    case allTasks = "all_tasks"
    case habits = "habits"
    case list = "list"
    
    var displayName: String {
        switch self {
        case .allTasks: return "All Tasks"
        case .habits: return "Habits"
        case .list: return "List"
        }
    }
}

// MARK: - Timeline Entry

struct TaskItEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskItem]
    let habits: [HabitItem]
    let lists: [ListItem]
    let displayMode: DisplayMode
    let selectedListId: Int?
    let userId: String?
    let isConfigured: Bool
}

// MARK: - User Defaults (Shared Config)

extension UserDefaults {
    static let widgetGroup = UserDefaults(suiteName: "group.com.example.taskit") ?? .standard
    
    var widgetUserId: String? {
        get { string(forKey: "widget_user_id") }
        set { set(newValue, forKey: "widget_user_id") }
    }
    
    var widgetDisplayMode: String {
        get { string(forKey: "widget_display_mode") ?? "all_tasks" }
        set { set(newValue, forKey: "widget_display_mode") }
    }
    
    var widgetSelectedListId: Int? {
        get { integer(forKey: "widget_list_id") == 0 ? nil : integer(forKey: "widget_list_id") }
        set { set(newValue, forKey: "widget_list_id") }
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TaskItEntry {
        TaskItEntry(
            date: Date(),
            tasks: [
                TaskItem(id: 1, title: "Example Task", detail: nil, is_completed: false, priority: "medium", list_id: nil, due_date: nil),
                TaskItem(id: 2, title: "Another Task", detail: "With details", is_completed: true, priority: "none", list_id: nil, due_date: nil),
            ],
            habits: [],
            lists: [],
            displayMode: .allTasks,
            selectedListId: nil,
            userId: nil,
            isConfigured: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskItEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskItEntry>) -> ()) {
        Task {
            let defaults = UserDefaults.widgetGroup
            let userId = defaults.widgetUserId
            let modeString = defaults.widgetDisplayMode
            let mode = DisplayMode(rawValue: modeString) ?? .allTasks
            let listId = defaults.widgetSelectedListId
            
            guard let userId = userId, !userId.isEmpty else {
                let entry = TaskItEntry(
                    date: Date(),
                    tasks: [], habits: [], lists: [],
                    displayMode: mode,
                    selectedListId: nil,
                    userId: nil,
                    isConfigured: false
                )
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                completion(timeline)
                return
            }
            
            async let fetchedTasks = DirectusAPI.fetchTodos(userId: userId)
            async let fetchedHabits = DirectusAPI.fetchHabits(userId: userId)
            async let fetchedLists = DirectusAPI.fetchLists(userId: userId)
            
            let tasks = await fetchedTasks
            let habits = await fetchedHabits
            let lists = await fetchedLists
            
            let entry = TaskItEntry(
                date: Date(),
                tasks: tasks,
                habits: habits,
                lists: lists,
                displayMode: mode,
                selectedListId: listId,
                userId: userId,
                isConfigured: true
            )
            
            // Refresh every 15 minutes
            let nextUpdate = Date().addingTimeInterval(15 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - Widget Views

struct TaskRowView: View {
    let task: TaskItem
    
    var priorityColor: Color {
        switch task.priority {
        case "high": return .red
        case "medium": return .orange
        case "low": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: task.is_completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.is_completed ? .green : .gray)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(task.is_completed ? .gray : .primary)
                    .strikethrough(task.is_completed)
                    .lineLimit(1)
                
                if let detail = task.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if task.priority != nil && task.priority != "none" {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 2)
    }
}

struct HabitRowView: View {
    let habit: HabitItem
    
    var habitColor: Color {
        if let hex = habit.color {
            return Color(hex: hex)
        }
        return .purple
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = habit.icon, !icon.isEmpty {
                Text(icon)
                    .font(.system(size: 16))
            } else {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(habit.isCompleted ? habitColor : .gray)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(habit.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(habit.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if habit.current_streak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text("\(habit.current_streak)")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(habit.isCompleted ? habitColor : .gray.opacity(0.4))
                .font(.system(size: 16))
        }
        .padding(.vertical, 2)
    }
}

struct NotConfiguredView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "gear")
                .font(.system(size: 28))
                .foregroundColor(.gray)
            Text("Open TaskIt")
                .font(.system(size: 13, weight: .semibold))
            Text("Set your User ID in Settings to use this widget")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Main Widget View

struct TaskItWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if !entry.isConfigured {
            NotConfiguredView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    Image(systemName: headerIcon)
                        .foregroundColor(.purple)
                        .font(.system(size: 12))
                    Text(headerTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(itemCount)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Content
                contentView
            }
            .padding(12)
        }
    }
    
    var headerIcon: String {
        switch entry.displayMode {
        case .allTasks: return "checklist"
        case .habits: return "repeat"
        case .list: return "list.bullet"
        }
    }
    
    var headerTitle: String {
        switch entry.displayMode {
        case .allTasks: return "Tasks"
        case .habits: return "Habits"
        case .list:
            if let listId = entry.selectedListId,
               let list = entry.lists.first(where: { $0.id == listId }) {
                return list.title
            }
            return "List"
        }
    }
    
    var itemCount: String {
        switch entry.displayMode {
        case .allTasks:
            let incomplete = entry.tasks.filter { !$0.is_completed }.count
            return "\(incomplete) left"
        case .habits:
            let done = entry.habits.filter { $0.isCompleted }.count
            return "\(done)/\(entry.habits.count)"
        case .list:
            let listTasks = entry.tasks.filter { $0.list_id == entry.selectedListId && !$0.is_completed }
            return "\(listTasks.count) left"
        }
    }
    
    var maxItems: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        case .systemLarge: return 8
        default: return 4
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        switch entry.displayMode {
        case .allTasks:
            let incomplete = entry.tasks.filter { !$0.is_completed }.prefix(maxItems)
            if incomplete.isEmpty {
                emptyView(message: "All done! 🎉")
            } else {
                ForEach(Array(incomplete)) { task in
                    Link(destination: URL(string: "taskit://complete-task/\(task.id)")!) {
                        TaskRowView(task: task)
                    }
                }
            }
            
        case .habits:
            let habitsList = Array(entry.habits.prefix(maxItems))
            if habitsList.isEmpty {
                emptyView(message: "No habits yet")
            } else {
                ForEach(habitsList) { habit in
                    Link(destination: URL(string: "taskit://toggle-habit/\(habit.id)")!) {
                        HabitRowView(habit: habit)
                    }
                }
            }
            
        case .list:
            let listTasks = entry.tasks
                .filter { $0.list_id == entry.selectedListId && !$0.is_completed }
                .prefix(maxItems)
            if listTasks.isEmpty {
                emptyView(message: "No tasks in this list")
            } else {
                ForEach(Array(listTasks)) { task in
                    Link(destination: URL(string: "taskit://complete-task/\(task.id)")!) {
                        TaskRowView(task: task)
                    }
                }
            }
        }
    }
    
    func emptyView(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget Declaration

@main
struct RunnerWidget: Widget {
    let kind: String = "RunnerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TaskItWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TaskIt")
        .description("View and complete your tasks and habits.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

struct RunnerWidget_Previews: PreviewProvider {
    static var previews: some View {
        TaskItWidgetEntryView(entry: TaskItEntry(
            date: Date(),
            tasks: [
                TaskItem(id: 1, title: "Buy groceries", detail: "Milk, eggs, bread", is_completed: false, priority: "medium", list_id: nil, due_date: nil),
                TaskItem(id: 2, title: "Call dentist", detail: nil, is_completed: false, priority: "high", list_id: nil, due_date: nil),
                TaskItem(id: 3, title: "Review PR", detail: nil, is_completed: true, priority: "none", list_id: nil, due_date: nil),
            ],
            habits: [
                HabitItem(id: 1, title: "Drink Water", detail: nil, icon: "💧", color: "#2196F3", target_count: 1, current_progress: 0, current_streak: 5, best_streak: 12),
                HabitItem(id: 2, title: "Exercise", detail: nil, icon: "💪", color: "#4CAF50", target_count: 1, current_progress: 1, current_streak: 3, best_streak: 10),
            ],
            lists: [],
            displayMode: .allTasks,
            selectedListId: nil,
            userId: "test",
            isConfigured: true
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
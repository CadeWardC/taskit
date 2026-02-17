import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Cached Defaults (widget extension sandbox)

struct CachedDefaults {
    static let userIdKey = "cached_user_id"

    /// Cached userId from the last widget config — used by ListEntityQuery
    static var userId: String? {
        get { UserDefaults.standard.string(forKey: userIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }
}

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
        guard let encoded = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseUrl)/items/todos?filter[user_id][_eq]=\(encoded)") else { return [] }
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
        guard let encoded = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseUrl)/items/habits?filter[user_id][_eq]=\(encoded)") else { return [] }
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
        guard let encoded = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseUrl)/items/lists?filter[user_id][_eq]=\(encoded)") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(DirectusResponse<ListItem>.self, from: data)
            return response.data
        } catch {
            print("Error fetching lists: \(error)")
            return []
        }
    }

    static func completeTask(taskId: Int) async -> Bool {
        guard let url = URL(string: "\(baseUrl)/items/todos/\(taskId)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["is_completed": true])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
            }
            return false
        } catch {
            print("Error completing task: \(error)")
            return false
        }
    }

    static func incrementHabit(habitId: Int, newProgress: Int) async -> Bool {
        guard let url = URL(string: "\(baseUrl)/items/habits/\(habitId)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["current_progress": newProgress])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
            }
            return false
        } catch {
            print("Error incrementing habit: \(error)")
            return false
        }
    }
}

struct DirectusResponse<T: Codable>: Codable {
    let data: [T]
}

// MARK: - Interactive App Intents

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description: IntentDescription = "Mark a task as completed"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task ID")
    var taskId: Int

    init() {}

    init(taskId: Int) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        let _ = await DirectusAPI.completeTask(taskId: taskId)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Habit"
    static var description: IntentDescription = "Increment habit progress"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Habit ID")
    var habitId: Int

    @Parameter(title: "New Progress")
    var newProgress: Int

    init() {}

    init(habitId: Int, currentProgress: Int, targetCount: Int) {
        self.habitId = habitId
        self.newProgress = min(currentProgress + 1, targetCount)
    }

    func perform() async throws -> some IntentResult {
        let _ = await DirectusAPI.incrementHabit(habitId: habitId, newProgress: newProgress)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - List App Entity for Dynamic Dropdown

struct ListAppEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "List"
    static var defaultQuery = ListEntityQuery()

    var id: Int
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}

struct ListEntityQuery: EntityQuery {
    func entities(for identifiers: [ListAppEntity.ID]) async throws -> [ListAppEntity] {
        guard let userId = CachedDefaults.userId else { return [] }
        let lists = await DirectusAPI.fetchLists(userId: userId)
        return lists
            .filter { identifiers.contains($0.id) }
            .map { ListAppEntity(id: $0.id, title: $0.title) }
    }

    func suggestedEntities() async throws -> [ListAppEntity] {
        guard let userId = CachedDefaults.userId else { return [] }
        let lists = await DirectusAPI.fetchLists(userId: userId)
        return lists.map { ListAppEntity(id: $0.id, title: $0.title) }
    }

    func defaultResult() async -> ListAppEntity? {
        return nil
    }
}

// MARK: - App Intent Configuration

enum DisplayMode: String, AppEnum {
    case allTasks = "all_tasks"
    case habits = "habits"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Display Mode"
    static var caseDisplayRepresentations: [DisplayMode: DisplayRepresentation] = [
        .allTasks: "Tasks",
        .habits: "Habits",
    ]
}

struct TaskItWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "TaskIt Widget"
    static var description: IntentDescription = "Configure what your TaskIt widget displays."

    @Parameter(title: "User ID")
    var userId: String?

    @Parameter(title: "Display Mode", default: .allTasks)
    var displayMode: DisplayMode

    @Parameter(title: "List")
    var listEntity: ListAppEntity?

    static var parameterSummary: some ParameterSummary {
        When(\.$displayMode, .equalTo, .allTasks) {
            Summary("\(\.$userId) — \(\.$displayMode)") {
                \.$listEntity
            }
        } otherwise: {
            Summary("\(\.$userId) — \(\.$displayMode)")
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

// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TaskItEntry {
        TaskItEntry(
            date: Date(),
            tasks: [
                TaskItem(id: 1, title: "Example Task", detail: nil, is_completed: false, priority: "medium", list_id: nil, due_date: nil),
                TaskItem(id: 2, title: "Another Task", detail: "With details", is_completed: false, priority: "none", list_id: nil, due_date: nil),
            ],
            habits: [],
            lists: [],
            displayMode: .allTasks,
            selectedListId: nil,
            userId: nil,
            isConfigured: true
        )
    }

    func snapshot(for configuration: TaskItWidgetIntent, in context: Context) async -> TaskItEntry {
        return placeholder(in: context)
    }

    func timeline(for configuration: TaskItWidgetIntent, in context: Context) async -> Timeline<TaskItEntry> {
        let userId = configuration.userId
        let mode = configuration.displayMode
        let selectedListId = configuration.listEntity?.id

        guard let userId = userId, !userId.isEmpty else {
            let entry = TaskItEntry(
                date: Date(),
                tasks: [], habits: [], lists: [],
                displayMode: mode,
                selectedListId: nil,
                userId: nil,
                isConfigured: false
            )
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        }

        // Cache userId so ListEntityQuery can access it for the list dropdown
        CachedDefaults.userId = userId

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
            selectedListId: selectedListId,
            userId: userId,
            isConfigured: true
        )

        // Refresh every 15 minutes
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
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
            Text("Setup Required")
                .font(.system(size: 13, weight: .semibold))
            Text("Long-press the widget and tap Edit to set your User ID")
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
        case .allTasks:
            if entry.selectedListId != nil {
                return "list.bullet"
            }
            return "checklist"
        case .habits: return "repeat"
        }
    }

    var headerTitle: String {
        switch entry.displayMode {
        case .allTasks:
            if let listId = entry.selectedListId,
               let list = entry.lists.first(where: { $0.id == listId }) {
                return list.title
            }
            return "Tasks"
        case .habits: return "Habits"
        }
    }

    var filteredTasks: [TaskItem] {
        var tasks = entry.tasks.filter { !$0.is_completed }

        if let listId = entry.selectedListId {
            tasks = tasks.filter { $0.list_id == listId }
        }

        return tasks
    }

    var itemCount: String {
        switch entry.displayMode {
        case .allTasks:
            return "\(filteredTasks.count) left"
        case .habits:
            let done = entry.habits.filter { $0.isCompleted }.count
            return "\(done)/\(entry.habits.count)"
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
            let items = Array(filteredTasks.prefix(maxItems))
            if items.isEmpty {
                emptyView(message: "All done!")
            } else {
                ForEach(items) { task in
                    Button(intent: ToggleTaskIntent(taskId: task.id)) {
                        TaskRowView(task: task)
                    }
                    .buttonStyle(.plain)
                }
            }

        case .habits:
            let habitsList = Array(entry.habits.prefix(maxItems))
            if habitsList.isEmpty {
                emptyView(message: "No habits yet")
            } else {
                ForEach(habitsList) { habit in
                    Button(intent: ToggleHabitIntent(
                        habitId: habit.id,
                        currentProgress: habit.current_progress,
                        targetCount: habit.target_count
                    )) {
                        HabitRowView(habit: habit)
                    }
                    .buttonStyle(.plain)
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
        AppIntentConfiguration(kind: kind, intent: TaskItWidgetIntent.self, provider: Provider()) { entry in
            TaskItWidgetEntryView(entry: entry)
                .widgetBackground()
        }
        .configurationDisplayName("TaskIt")
        .description("View your tasks and habits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// iOS 17+ containerBackground compatibility
extension View {
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return AnyView(self.containerBackground(.fill.tertiary, for: .widget))
        } else {
            return AnyView(self.background(Color(.systemBackground)))
        }
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
                TaskItem(id: 3, title: "Review PR", detail: nil, is_completed: false, priority: "none", list_id: nil, due_date: nil),
            ],
            habits: [
                HabitItem(id: 1, title: "Drink Water", detail: nil, icon: "\u{1F4A7}", color: "#2196F3", target_count: 1, current_progress: 0, current_streak: 5, best_streak: 12),
                HabitItem(id: 2, title: "Exercise", detail: nil, icon: "\u{1F4AA}", color: "#4CAF50", target_count: 1, current_progress: 1, current_streak: 3, best_streak: 10),
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

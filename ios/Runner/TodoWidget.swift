import WidgetKit
import SwiftUI

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoItem]
}

struct TodoItem: Codable, Identifiable {
    let id: Int?
    let count: Int?
    let title: String
    let is_completed: Bool
    
    // Use id as the unique identifier for SwiftUI
    var identifiableId: Int { id ?? 0 }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), todos: [
            TodoItem(id: 1, count: null, title: "Buy Milk", is_completed: false),
            TodoItem(id: 2, count: 5, title: "Drink Water (Habit)", is_completed: true)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> ()) {
        let entry = TodoEntry(date: Date(), todos: [
            TodoItem(id: 1, count: null, title: "Buy Milk", is_completed: false),
            TodoItem(id: 2, count: 5, title: "Drink Water (Habit)", is_completed: true)
        ])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> ()) {
        var entries: [TodoEntry] = []
        
        // Define the App Group ID - MUST MATCH XCODE CAPABILITY
        let userDefaults = UserDefaults(suiteName: "group.com.example.taskit")
        let todoData = userDefaults?.string(forKey: "todo_data")
        
        var todos: [TodoItem] = []
        
        if let todoData = todoData, let data = todoData.data(using: .utf8) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([TodoItem].self, from: data) {
                todos = decoded
            }
        }
        
        // If empty, show placeholder
        if todos.isEmpty {
             todos = [TodoItem(id: 0, count: null, title: "No tasks", is_completed: false)]
        }

        let entry = TodoEntry(date: Date(), todos: todos)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct TodoWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color(UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)
                
                ForEach(entry.todos.prefix(4), id: \.id) { todo in
                    HStack {
                        Image(systemName: todo.is_completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(todo.is_completed ? .gray : .purple)
                        Text(todo.title)
                            .font(.caption)
                            .strikethrough(todo.is_completed)
                            .foregroundColor(todo.is_completed ? .gray : .white)
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

@main
struct TodoWidget: Widget {
    let kind: String = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Tasks")
        .description("View your top tasks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

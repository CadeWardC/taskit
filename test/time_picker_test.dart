import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskit/presentation/widgets/task_widgets.dart';
import 'package:taskit/data/models/todo.dart';

void main() {
  testWidgets('TaskCard displays time when set', (WidgetTester tester) async {
    final dueDate = DateTime(2023, 10, 10, 14, 30); // 14:30 = 2:30 PM
    final todo = Todo(
      id: 1,
      title: 'Test Task',
      dueDate: dueDate,
      isCompleted: false,
      priority: 'medium',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            todo: todo,
            onToggle: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Ensure animations complete

    // Expect to find date and time
    // 10/10 2:30 PM
    expect(find.textContaining('10/10'), findsOneWidget);
    expect(find.textContaining('2:30 PM'), findsOneWidget);
  });

  testWidgets('TaskCard does NOT display time when 00:00', (WidgetTester tester) async {
    final dueDate = DateTime(2023, 10, 10, 0, 0); // Midnight
    final todo = Todo(
      id: 1,
      title: 'Test Task',
      dueDate: dueDate,
      isCompleted: false,
      priority: 'low',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            todo: todo,
            onToggle: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    
    await tester.pumpAndSettle();

    // Expect to find date but NOT time
    expect(find.textContaining('10/10'), findsOneWidget);
    expect(find.text('12:00 AM'), findsNothing);
    expect(find.text('00:00'), findsNothing);
  });
}

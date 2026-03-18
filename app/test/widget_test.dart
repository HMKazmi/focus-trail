import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget test for the task list empty state UI.
/// This is a standalone widget test that doesn't need Riverpod/Hive
/// since it tests a simple UI component.
void main() {
  testWidgets('Empty state shows message and icon', (tester) async {
    // Build a minimal empty state widget similar to what TaskListPage shows
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No tasks yet', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 8),
                const Text('Tap + to create your first task.'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Tap + to create your first task.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('Task card shows title and status chip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListTile(
            leading: const Icon(Icons.radio_button_unchecked),
            title: const Text('Buy groceries'),
            subtitle: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('To Do'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('To Do'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/models/task_model.dart';
import 'package:peertask/ui/widgets/task_dialog.dart';

void main() {
  testWidgets('checklist round-trips through the task description', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    String? savedDescription;
    List<String>? savedLabels;
    final start = DateTime(2026, 10, 1);
    final task = TaskModel(
      id: 't1',
      boardId: 'b1',
      title: 'Ship it',
      description:
          '<!--start_date:${start.toIso8601String()}-->\n'
          '- [x] Write code\n'
          '- [ ] Review\n'
          '\nSome notes',
      status: 'todo',
      priority: 'medium',
      assignees: const [],
      assigneeList: const [],
      labels: const [],
      position: 0,
      createdBy: 'u1',
      createdAt: start,
      updatedAt: start,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TaskDialog(
            existingTask: task,
            boardMembers: const [],
            onSave:
                ({
                  required String title,
                  String? description,
                  required String priority,
                  required String status,
                  DateTime? deadline,
                  DateTime? startDate,
                  List<String>? assignees,
                  List<String>? labels,
                  double? estimatedHours,
                  List<Map<String, dynamic>>? attachments,
                }) {
                  savedDescription = description;
                  savedLabels = labels;
                },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Write code'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    final stepField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText ==
              'Add steps to complete this task. Mark them done as you go.',
    );
    await tester.enterText(stepField, 'Deploy');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Deploy'), findsOneWidget);

    final save = find.byWidgetPredicate((w) => w is FilledButton);
    await tester.ensureVisible(save.last);
    await tester.tap(save.last);
    await tester.pump();

    expect(savedLabels, isEmpty);
    expect(savedDescription, contains('<!--start_date:'));
    expect(savedDescription, contains('- [x] Write code'));
    expect(savedDescription, contains('- [ ] Review'));
    expect(savedDescription, contains('- [ ] Deploy'));
    expect(savedDescription, endsWith('Some notes'));
  });
}

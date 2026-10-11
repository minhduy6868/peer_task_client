import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/models/board/board.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/providers/language_provider.dart';
import 'package:peertask/services/api_service.dart';
import 'package:peertask/services/storage_service.dart';
import 'package:peertask/ui/screens/board_screen.dart';
import 'package:peertask/ui/theme/app_theme.dart';

import 'package:peertask/models/operation/operation.dart';

class _FakeStorageService extends Fake implements StorageService {
  @override
  Future<void> saveLastWorkspace(String? workspaceId) async {}
  @override
  String? getLastWorkspace() => 'ws-1';
  @override
  String? getAuthToken() => 'dummy-token';
  @override
  Map<String, dynamic>? getUser() => {
        'id': 'user-1',
        'email': 'dev@peertask.com',
        'name': 'Alex Developer',
      };
  @override
  Future<void> saveUser(Map<String, dynamic> user) async {}
  @override
  Map<String, dynamic>? getBoardDraft(String boardId) => null;
  @override
  Future<void> saveBoardDraft(String boardId, Map<String, dynamic> draft) async {}
  @override
  Future<void> clearBoardDraft(String boardId) async {}
  @override
  List<Operation> getPendingOperations(String boardId) => const [];
  @override
  Future<void> clearPendingOperation(String boardId, String opId) async {}
}

class _FakeApiService extends Fake implements ApiService {
  @override
  String? get accessToken => 'dummy-token';

  @override
  String? get refreshToken => null;

  @override
  Future<void> loadTokens() async {}

  @override
  Future<void> clearTokens() async {}

  @override
  Future<void> saveOperation({
    required String boardId,
    required String operationId,
    required String operationType,
    required Map<String, dynamic> payload,
    required int timestamp,
  }) async {}

  @override
  Future<Board> getBoard(String boardId) async {
    return const Board(
      id: 'board-1',
      workspaceId: 'ws-1',
      name: 'Mobile App Tasks',
      description: 'Sprint 24 Kanban',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getBoardOperations(String boardId, {int? since}) async => [];

  @override
  Future<List<Map<String, dynamic>>> getWorkspaceMembers(String workspaceId) async {
    return [
      {'user_id': 'user-1', 'name': 'Alex Dev', 'email': 'dev@peertask.com', 'role': 'owner'},
      {'user_id': 'user-2', 'name': 'Sarah UX', 'email': 'sarah@peertask.com', 'role': 'editor'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getBoardMembers(String boardId) async {
    return [
      {'user_id': 'user-1', 'name': 'Alex Dev', 'email': 'dev@peertask.com', 'permission': 'owner'},
      {'user_id': 'user-2', 'name': 'Sarah UX', 'email': 'sarah@peertask.com', 'permission': 'editor'},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getBoardTasks(
    String boardId, {
    String? assigneeId,
    String? status,
    String? priority,
    String? parentId,
  }) async {
    return [
      {
        'id': 'task-1',
        'title': 'Customer Journey Mapping',
        'description': 'Mapping out UX flows and friction points',
        'status': 'todo',
        'priority': 'medium',
        'labels': ['Design'],
        'assignees': ['user-1', 'user-2'],
        'deadline': '2026-10-25T12:00:00Z',
      },
      {
        'id': 'task-2',
        'title': 'Database Customization',
        'description': 'Configuring PostgreSQL tables and indexing',
        'status': 'doing',
        'priority': 'high',
        'labels': ['Development'],
        'assignees': ['user-1'],
        'deadline': '2026-10-21T12:00:00Z',
      },
      {
        'id': 'task-3',
        'title': 'Redesign Marketing Website',
        'description': 'Polish hero and CTA sections',
        'status': 'done',
        'priority': 'low',
        'labels': ['Marketing'],
        'assignees': ['user-2'],
        'deadline': '2026-10-17T12:00:00Z',
      },
    ];
  }
}

class _FakeLanguageNotifier extends StateNotifier<Locale> implements LanguageNotifier {
  _FakeLanguageNotifier(super.initial);

  @override
  Future<void> setLanguage(String code) async {
    state = Locale(code);
  }

  @override
  void toggleLanguage() {
    state = Locale(state.languageCode == 'en' ? 'vi' : 'en');
  }
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(super.ref) {
    state = AuthState(
      user: const User(
        id: 'user-1',
        email: 'dev@peertask.com',
        name: 'Alex Developer',
        avatar: null,
      ),
      accessToken: 'dummy-token',
    );
  }
}

Widget _buildTestApp({
  required Widget child,
  Size size = const Size(1280, 800),
}) {
  final fakeApi = _FakeApiService();
  final fakeStorage = _FakeStorageService();

  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(fakeApi),
      storageServiceProvider.overrideWithValue(fakeStorage),
      currentBoardIdProvider.overrideWith((ref) => 'board-1'),
      languageProvider.overrideWith((ref) => _FakeLanguageNotifier(const Locale('vi'))),
      authStateProvider.overrideWith((ref) => _MockAuthNotifier(ref)),
      currentBoardProvider.overrideWith(
        (ref) async => const Board(
          id: 'board-1',
          workspaceId: 'ws-1',
          name: 'Mobile App Tasks',
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('BoardScreen renders Organix-style header, tabs, pastel column banners and task cards', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      _buildTestApp(
        child: const BoardScreen(boardId: 'board-1'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Board Title & Add Task button
    expect(find.text('Mobile App Tasks'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);

    // Verify sub-header view tabs (Board, Canvas)
    expect(find.byIcon(Icons.view_kanban_rounded), findsOneWidget);
    expect(find.byIcon(Icons.draw_rounded), findsOneWidget);

    // Verify Filter and Sort buttons
    expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
    expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);

    // Verify column headers (To Do, Doing, Done in Vietnamese: Cần làm, Đang làm, Hoàn thành)
    expect(find.text('Cần làm'), findsWidgets);
    expect(find.text('Đang làm'), findsWidgets);
    expect(find.text('Hoàn thành'), findsWidgets);

    // Verify task cards loaded from board
    expect(find.text('Customer Journey Mapping'), findsOneWidget);
    expect(find.text('Database Customization'), findsOneWidget);
    expect(find.text('Redesign Marketing Website'), findsOneWidget);

    // Verify uppercase category tags
    expect(find.text('DESIGN'), findsOneWidget);
    expect(find.text('DEVELOPMENT'), findsOneWidget);
    expect(find.text('MARKETING'), findsOneWidget);
  });

  testWidgets('BoardScreen adapts responsively on phone viewport without layout overflow', (tester) async {
    // Typical mobile screen: 390 x 844 (iPhone 14 / modern Android)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      _buildTestApp(
        size: const Size(390, 844),
        child: const BoardScreen(boardId: 'board-1'),
      ),
    );
    await tester.pumpAndSettle();

    // Must not throw any RenderFlex overflow exception
    expect(tester.takeException(), isNull);

    // Filter toggle works cleanly on mobile
    final filterButton = find.byIcon(Icons.filter_list_rounded);
    expect(filterButton, findsOneWidget);
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    // Filter toolbar is visible with search input
    expect(find.byType(TextField), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

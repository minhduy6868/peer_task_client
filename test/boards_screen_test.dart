import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/models/board/board.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/models/workspace/workspace.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/providers/language_provider.dart';
import 'package:peertask/services/api_service.dart';
import 'package:peertask/services/storage_service.dart';
import 'package:peertask/ui/screens/boards_screen.dart';
import 'package:peertask/ui/screens/workspace_home_screen.dart';
import 'package:peertask/ui/theme/app_theme.dart';

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
  Future<Workspace> getWorkspace(String id) async {
    return const Workspace(
      id: 'ws-1',
      name: 'Team Alpha',
      role: 'owner',
      ownerId: 'user-1',
      createdAt: null,
      updatedAt: null,
    );
  }

  @override
  Future<List<Board>> getWorkspaceBoards(String workspaceId) async {
    return const [
      Board(
        id: 'board-1',
        workspaceId: 'ws-1',
        name: 'Sprint Planning',
        description: 'Current sprint tasks',
      ),
      Board(
        id: 'board-2',
        workspaceId: 'ws-1',
        name: 'Design System',
        description: 'Component specs',
      ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getWorkspaceBoardSummary(String workspaceId) async {
    return [
      {
        'board_id': 'board-1',
        'todo_count': 3,
        'doing_count': 2,
        'done_count': 5,
        'overdue_count': 0,
      },
      {
        'board_id': 'board-2',
        'todo_count': 1,
        'doing_count': 0,
        'done_count': 2,
        'overdue_count': 0,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getMyTasks({
    String? workspaceId,
    String? status,
    bool open = true,
    int limit = 8,
  }) async {
    return [
      {
        'id': 'task-1',
        'title': 'Redesign home dashboard',
        'board_id': 'board-1',
        'board_name': 'Sprint Planning',
        'status': 'doing',
        'priority': 'high',
        'deadline': null,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getBoardMembers(String boardId) async {
    return [
      {
        'user_id': 'user-1',
        'name': 'Alex Developer',
        'email': 'dev@peertask.com',
        'permission': 'edit',
        'is_board_owner': true,
        'workspace_role': 'owner',
      },
      {
        'user_id': 'user-2',
        'name': 'Sarah Connor',
        'email': 'sarah@peertask.com',
        'permission': 'view',
        'is_board_owner': false,
        'workspace_role': 'viewer',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({required Widget home, Locale locale = const Locale('vi')}) {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(_FakeApiService()),
        storageServiceProvider.overrideWithValue(_FakeStorageService()),
        authStateProvider.overrideWith((ref) => _MockAuthNotifier(ref)),
        languageProvider.overrideWith((ref) => _FakeLanguageNotifier(const Locale('en'))),
      ],
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('BoardsScreen renders dashboard hero, metrics, and board cards without layout issues', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(home: const BoardsScreen(workspaceId: 'ws-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Alex Developer'), findsOneWidget);
    expect(find.text('Sprint Planning'), findsWidgets);
    expect(find.text('Design System'), findsOneWidget);
    expect(find.text('Redesign home dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WorkspaceHomeScreen renders rail with brand mark and items', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(home: const WorkspaceHomeScreen(workspaceId: 'ws-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.diversity_3_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.diversity_3_rounded));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('BoardsScreen displays member count, role badges, and filter chips', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(home: const BoardsScreen(workspaceId: 'ws-1'), locale: const Locale('vi')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Role badges & member counts on board cards
    expect(find.text('Chủ sở hữu'), findsWidgets);
    expect(find.text('2 thành viên'), findsWidgets);

    // Filter chips
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Chỉnh sửa'), findsOneWidget);
    expect(find.text('Chỉ xem'), findsOneWidget);

    // Tap Editor filter chip -> 0 matching boards
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Không có bảng nào khớp với bộ lọc'), findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsWidgets);

    // Tap Clear filter -> restores boards
    await tester.tap(find.text('Xóa bộ lọc').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Sprint Planning'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BoardsScreen adapts responsively on mobile phone without layout issues', (tester) async {
    // Mobile phone screen: 390x844 (iPhone 14 / modern Android)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(home: const BoardsScreen(workspaceId: 'ws-1'), locale: const Locale('vi')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Segmented tab switch on mobile
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.text('Sprint Planning'), findsOneWidget);
    expect(find.text('Design System'), findsOneWidget);

    // Switch to "Công việc của bạn" (Your work) tab via SegmentedButton
    await tester.tap(find.descendant(
      of: find.byType(SegmentedButton<int>),
      matching: find.byIcon(Icons.assignment_turned_in_rounded),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Redesign home dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

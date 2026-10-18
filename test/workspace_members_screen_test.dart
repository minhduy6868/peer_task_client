import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/services/api_service.dart';
import 'package:peertask/services/storage_service.dart';
import 'package:peertask/ui/screens/workspace_members_screen.dart';

class _FakeStorageService extends Fake implements StorageService {
  @override
  String? getAuthToken() => 'dummy-token';
  @override
  Map<String, dynamic>? getUser() => {
        'id': 'u1',
        'email': 'duy2@gmail.com',
        'name': 'duy2',
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
  Future<List<Map<String, dynamic>>> getWorkspaceMembers(String workspaceId) async {
    return [
      {
        'id': 'u1',
        'name': 'duy2',
        'email': 'duy2@gmail.com',
        'role': 'owner',
      },
      {
        'id': 'u2',
        'name': 'Nguyễn Văn Nam',
        'email': 'nam.nv@peertask.com',
        'role': 'editor',
      },
    ];
  }
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(super.ref) {
    state = AuthState(
      user: const User(
        id: 'u1',
        email: 'duy2@gmail.com',
        name: 'duy2',
      ),
      accessToken: 'dummy-token',
    );
  }
}

Widget _buildTestApp({Locale locale = const Locale('vi')}) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(_FakeApiService()),
      storageServiceProvider.overrideWithValue(_FakeStorageService()),
      authStateProvider.overrideWith((ref) => _MockAuthNotifier(ref)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(
        body: WorkspaceMembersScreen(workspaceId: 'ws-1'),
      ),
    ),
  );
}

void main() {
  testWidgets('WorkspaceMembersScreen renders invite button, search, filters and members table',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // 1. Nút + Mời thành viên
    expect(find.text('Mời thành viên'), findsWidgets);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);

    // 2. Ô tìm kiếm
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tìm kiếm theo tên hoặc email...'), findsOneWidget);

    // 3. Bộ lọc theo vai trò và trạng thái
    expect(find.byType(DropdownButton<String>), findsWidgets);

    // 4. Bảng thành viên với avatar, tên, email, vai trò, số task, trạng thái
    expect(find.text('duy2'), findsOneWidget);
    expect(find.text('duy2@gmail.com'), findsOneWidget);
    expect(find.text('Nguyễn Văn Nam'), findsOneWidget);
    expect(find.text('nam.nv@peertask.com'), findsOneWidget);

    // Roles and task count
    expect(find.text('Chủ sở hữu'), findsWidgets);
    expect(find.text('Người chỉnh sửa'), findsWidgets);
    expect(find.textContaining('công việc'), findsWidgets);

    // 5. Mở dialog mời thành viên
    final inviteBtn = find.ancestor(
      of: find.text('Mời thành viên'),
      matching: find.byWidgetPredicate((w) => w is ElevatedButton),
    );
    await tester.tap(inviteBtn.first);
    await tester.pumpAndSettle();

    expect(find.text('Mời bằng email'), findsOneWidget);
    expect(find.text('Tạo link mời'), findsOneWidget);
    expect(find.text('Gửi'), findsOneWidget);
  });
}

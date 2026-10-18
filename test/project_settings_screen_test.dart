import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/models/workspace/workspace.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/services/api_service.dart';
import 'package:peertask/services/storage_service.dart';
import 'package:peertask/ui/screens/project_settings_screen.dart';

class _FakeStorageService extends Fake implements StorageService {
  @override
  String? getAuthToken() => 'dummy-token';
  @override
  Map<String, dynamic>? getUser() => {
        'id': 'u1',
        'email': 'duy2@gmail.com',
        'name': 'duy2',
      };
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
      name: 'Sprint 1',
      role: 'owner',
      ownerId: 'u1',
      createdAt: null,
      updatedAt: null,
    );
  }

  @override
  Future<Workspace> updateWorkspace({required String workspaceId, required String name}) async {
    return Workspace(
      id: workspaceId,
      name: name,
      role: 'owner',
      ownerId: 'u1',
      createdAt: null,
      updatedAt: null,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getWorkspaceMembers(String workspaceId) async {
    return [
      {'id': 'u1', 'name': 'duy2', 'email': 'duy2@gmail.com', 'role': 'owner'},
      {'id': 'u2', 'name': 'Nguyễn Văn Nam', 'email': 'nam.nv@peertask.com', 'role': 'admin'},
    ];
  }
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(super.ref, {String userId = 'u1', String email = 'duy2@gmail.com', String name = 'duy2'}) {
    state = AuthState(
      user: User(id: userId, email: email, name: name),
      accessToken: 'dummy-token',
    );
  }
}

Widget _buildTestApp({
  String userId = 'u1',
  String email = 'duy2@gmail.com',
  Locale locale = const Locale('vi'),
}) {
  return ProviderScope(
    overrides: [
      apiServiceProvider.overrideWithValue(_FakeApiService()),
      storageServiceProvider.overrideWithValue(_FakeStorageService()),
      authStateProvider.overrideWith((ref) => _MockAuthNotifier(ref, userId: userId, email: email)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(
        body: ProjectSettingsScreen(workspaceId: 'ws-1'),
      ),
    ),
  );
}

void main() {
  testWidgets('ProjectSettingsScreen renders 6 sections and allows editing for Owner', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // 1. Kiểm tra 6 Tab cài đặt dự án
    expect(find.text('Thông tin dự án'), findsWidgets);
    expect(find.text('Thành viên và quyền hạn'), findsWidgets);
    expect(find.text('Quy trình công việc'), findsWidgets);
    expect(find.text('Thời gian và tiến độ'), findsWidgets);
    expect(find.text('Quyền truy cập'), findsWidgets);
    expect(find.text('Lưu trữ và xóa dự án'), findsWidgets);

    // 2. Tab 1: Thông tin dự án
    expect(find.text('Tên dự án'), findsOneWidget);
    expect(find.text('Sprint 1'), findsOneWidget);
    expect(find.text('Mô tả dự án'), findsOneWidget);
    expect(find.text('Chủ sở hữu dự án'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);

    // Đổi tên Sprint 1 thành Sprint 2
    final nameField = find.widgetWithText(TextField, 'Sprint 1');
    await tester.enterText(nameField, 'Sprint 2');
    await tester.pumpAndSettle();
    expect(find.text('Sprint 2'), findsOneWidget);

    // 3. Chuyển sang Tab 2: Thành viên và quyền hạn
    await tester.tap(find.text('Thành viên và quyền hạn').first);
    await tester.pumpAndSettle();
    expect(find.text('Danh sách thành viên (2)'), findsOneWidget);
    expect(find.text('Nguyễn Văn Nam'), findsOneWidget);
    expect(find.text('Quản trị viên'), findsWidgets);

    // 4. Chuyển sang Tab 3: Quy trình công việc
    await tester.tap(find.text('Quy trình công việc').first);
    await tester.pumpAndSettle();
    expect(find.text('Quy trình các bước thực hiện task (Pipeline)'), findsOneWidget);
    expect(find.text('Cần làm'), findsWidgets);
    expect(find.text('Đang làm'), findsWidgets);
    expect(find.text('Chờ duyệt'), findsWidgets);
    expect(find.text('Hoàn thành'), findsWidgets);
    expect(find.text('Yêu cầu người phụ trách (Assignee)'), findsOneWidget);

    // 5. Chuyển sang Tab 4: Thời gian và tiến độ
    await tester.tap(find.text('Thời gian và tiến độ').first);
    await tester.pumpAndSettle();
    expect(find.text('Thời gian thực hiện dự án'), findsOneWidget);
    expect(find.text('2 tuần (Khuyên dùng)'), findsOneWidget);
    expect(find.text('Theo số lượng công việc (Task Count)'), findsOneWidget);

    // 6. Chuyển sang Tab 5: Quyền truy cập
    await tester.tap(find.text('Quyền truy cập').first);
    await tester.pumpAndSettle();
    expect(find.text('Chế độ hiển thị dự án'), findsOneWidget);
    expect(find.text('Dự án Riêng tư (Private - Khuyên dùng)'), findsOneWidget);

    // 7. Chuyển sang Tab 6: Lưu trữ và xóa dự án
    await tester.tap(find.text('Lưu trữ và xóa dự án').first);
    await tester.pumpAndSettle();
    expect(find.text('Lưu trữ dự án'), findsWidgets);
    expect(find.text('Xóa dự án'), findsWidgets);
  });

  testWidgets('ProjectSettingsScreen blocks access when current user is not Owner', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final nonOwnerApp = ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(_FakeNonOwnerApiService()),
        storageServiceProvider.overrideWithValue(_FakeStorageService()),
        authStateProvider.overrideWith((ref) => _MockAuthNotifier(ref, userId: 'other-user', email: 'guest@peertask.com', name: 'Guest User')),
      ],
      child: const MaterialApp(
        locale: Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ProjectSettingsScreen(workspaceId: 'ws-1'),
        ),
      ),
    );

    await tester.pumpWidget(nonOwnerApp);
    await tester.pumpAndSettle();

    // Phải hiển thị màn hình từ chối quyền truy cập
    expect(find.text('Chỉ dành cho chủ sở hữu'), findsOneWidget);
    expect(find.text('Quay lại Trang chủ'), findsOneWidget);
    expect(find.byIcon(Icons.lock_person_rounded), findsOneWidget);
  });
}

class _FakeNonOwnerApiService extends _FakeApiService {
  @override
  Future<Workspace> getWorkspace(String id) async {
    return const Workspace(
      id: 'ws-1',
      name: 'Sprint 1',
      role: 'editor',
      ownerId: 'owner-user-99',
      createdAt: null,
      updatedAt: null,
    );
  }
}

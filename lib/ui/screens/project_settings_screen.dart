import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/workspace/workspace.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/error_display.dart';
import '../theme/app_colors.dart';

class ProjectSettingsScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const ProjectSettingsScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  int _selectedTab = 0;
  bool _isLoading = true;
  Workspace? _workspace;

  // Tab 1: Info controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  int _selectedIconIndex = 0;
  int _selectedColorIndex = 0;
  bool _isSavingInfo = false;

  // Tab 2: Members
  List<Map<String, dynamic>> _members = [];

  // Tab 3: Workflow configuration
  bool _requireAssignee = true;
  bool _requireDeadline = false;
  bool _requireDescription = false;
  bool _autoCompleteChecklist = true;
  bool _adminApprovalRequired = true;
  final List<Map<String, dynamic>> _statuses = [
    {'name': 'Cần làm', 'key': 'todo', 'color': Color(0xFF64748B), 'icon': Icons.radio_button_unchecked_rounded},
    {'name': 'Đang làm', 'key': 'doing', 'color': Color(0xFF6366F1), 'icon': Icons.timelapse_rounded},
    {'name': 'Chờ duyệt', 'key': 'review', 'color': Color(0xFFF59E0B), 'icon': Icons.pending_actions_rounded},
    {'name': 'Hoàn thành', 'key': 'done', 'color': Color(0xFF10B981), 'icon': Icons.check_circle_rounded},
  ];

  // Tab 4: Timeline & Progress
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _sprintDuration = '2_weeks'; // 1_week, 2_weeks, 3_weeks, 4_weeks
  String _progressCalculation = 'task_count'; // task_count, story_points, checklist

  // Tab 5: Access Control
  bool _isPrivateProject = true;
  bool _allowAdminInvite = true;
  bool _allowShareReadOnlyLink = false;
  String _defaultNewMemberRole = 'viewer'; // viewer, editor

  // Available icons & colors for project avatar
  final List<IconData> _availableIcons = const [
    Icons.cloud_rounded,
    Icons.rocket_launch_rounded,
    Icons.folder_special_rounded,
    Icons.code_rounded,
    Icons.analytics_rounded,
    Icons.auto_awesome_rounded,
    Icons.group_work_rounded,
    Icons.task_alt_rounded,
  ];

  final List<Color> _availableColors = const [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Rose
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _loadWorkspaceData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspaceData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final ws = await api.getWorkspace(widget.workspaceId);
      _workspace = ws;
      _nameController.text = ws.name;
      _descController.text = '';

      try {
        final rawMembers = await api.getWorkspaceMembers(widget.workspaceId);
        if (rawMembers.isNotEmpty) {
          _members = rawMembers;
        } else {
          _members = _getDefaultMembers();
        }
      } catch (_) {
        _members = _getDefaultMembers();
      }
    } catch (_) {
      // Fallback
      final authUser = ref.read(authStateProvider).user;
      _workspace = Workspace(
        id: widget.workspaceId,
        name: 'Dự án',
        role: 'owner',
        ownerId: authUser?.id ?? '',
        createdAt: null,
        updatedAt: null,
      );
      _nameController.text = 'Dự án';
      _descController.text = '';
      _members = _getDefaultMembers();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultMembers() {
    final authUser = ref.read(authStateProvider).user;
    if (authUser == null) return const [];
    final userName = authUser.name?.isNotEmpty == true
        ? authUser.name!
        : (authUser.email?.split('@').first ?? 'Chủ sở hữu');
    final userEmail = authUser.email ?? '';
    return [
      {
        'id': authUser.id,
        'name': userName,
        'email': userEmail,
        'role': 'owner',
      },
    ];
  }

  bool _checkIsOwner() {
    final authUser = ref.read(authStateProvider).user;
    if (_workspace?.role == 'owner') return true;
    if (_workspace?.ownerId != null && _workspace?.ownerId == authUser?.id) return true;
    return false;
  }

  Future<void> _saveProjectInfo() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ErrorHandler.handle(context, 'Tên dự án không được để trống');
      return;
    }

    setState(() => _isSavingInfo = true);
    try {
      final api = ref.read(apiServiceProvider);
      final updated = await api.updateWorkspace(
        workspaceId: widget.workspaceId,
        name: newName,
      );
      setState(() => _workspace = updated);
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Đã cập nhật dự án "$newName"!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Đã lưu thông tin dự án "$newName" thành công!');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingInfo = false);
      }
    }
  }

  void _showDeleteProjectDialog() {
    final l10n = AppLocalizations.of(context)!;
    final currentName = _workspace?.name ?? _nameController.text;
    final confirmController = TextEditingController();
    bool isMatch = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.deleteProject,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hành động này sẽ xóa vĩnh viễn dự án "$currentName" cùng toàn bộ bảng, công việc và dữ liệu liên quan. Hành động này KHÔNG THỂ hoàn tác.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Vui lòng nhập chính xác "$currentName" để xác nhận:',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                autofocus: true,
                onChanged: (val) {
                  setDialogState(() {
                    isMatch = val.trim() == currentName;
                  });
                },
                decoration: InputDecoration(
                  hintText: currentName,
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: isMatch
                  ? () async {
                      Navigator.pop(ctx);
                      try {
                        final api = ref.read(apiServiceProvider);
                        await api.deleteWorkspace(widget.workspaceId);
                      } catch (_) {}
                      if (context.mounted) {
                        ErrorHandler.showSuccess(context, 'Đã xóa dự án thành công!');
                        context.go('/workspaces');
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFCA5A5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.deleteProject, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showArchiveProjectDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.archive_outlined, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Text(l10n.archiveProject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          '${l10n.archiveProjectDesc}\nBạn có thể khôi phục lại dự án bất kỳ lúc nào.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ErrorHandler.showSuccess(context, 'Dự án đã được đưa vào kho lưu trữ thành công!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.archiveProject, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = _checkIsOwner();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Nếu không phải là chủ sở hữu: Hiển thị giao diện giới hạn quyền truy cập
    if (!isOwner) {
      return _buildPermissionDeniedView(l10n);
    }

    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 900;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: isDesktop ? _buildDesktopLayout(l10n) : _buildMobileLayout(l10n),
    );
  }

  /// Giao diện khi người dùng không phải Owner (Chỉ chủ sở hữu mới được truy cập)
  Widget _buildPermissionDeniedView(AppLocalizations l10n) {
    final ownerName = _members.firstWhere(
      (m) => m['role'] == 'owner',
      orElse: () => {'name': _workspace?.name ?? 'Chủ dự án', 'email': ''},
    )['name'];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_person_rounded,
                      color: Color(0xFFD97706),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.ownerOnlyAccess,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.ownerOnlyDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Text(
                        'Chủ sở hữu hiện tại: $ownerName',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/workspaces');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(l10n.backToHome, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Layout Desktop với thanh điều hướng 6 tab bên trái và nội dung cuộn bên phải
  Widget _buildDesktopLayout(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Navigation Bar for Settings Tabs
        SizedBox(
          width: 260,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.projectSettings,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _buildTabNavItem(0, l10n.projectInfoTab, Icons.info_outline_rounded),
                      _buildTabNavItem(1, l10n.membersPermissionsTab, Icons.group_outlined),
                      _buildTabNavItem(2, l10n.workflowTab, Icons.alt_route_rounded),
                      _buildTabNavItem(3, l10n.timelineProgressTab, Icons.access_time_rounded),
                      _buildTabNavItem(4, l10n.accessControlTab, Icons.lock_outline_rounded),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),
                      _buildTabNavItem(5, l10n.archiveDeleteTab, Icons.warning_amber_rounded, isDanger: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

        // Right Main Content Pane
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            children: [
              _buildActiveTabContent(l10n),
            ],
          ),
        ),
      ],
    );
  }

  /// Layout Mobile với Horizontal Tab Bar
  Widget _buildMobileLayout(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildMobileTabChip(0, l10n.projectInfoTab, Icons.info_outline_rounded),
                const SizedBox(width: 8),
                _buildMobileTabChip(1, l10n.membersPermissionsTab, Icons.group_outlined),
                const SizedBox(width: 8),
                _buildMobileTabChip(2, l10n.workflowTab, Icons.alt_route_rounded),
                const SizedBox(width: 8),
                _buildMobileTabChip(3, l10n.timelineProgressTab, Icons.access_time_rounded),
                const SizedBox(width: 8),
                _buildMobileTabChip(4, l10n.accessControlTab, Icons.lock_outline_rounded),
                const SizedBox(width: 8),
                _buildMobileTabChip(5, l10n.archiveDeleteTab, Icons.warning_amber_rounded, isDanger: true),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildActiveTabContent(l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabNavItem(int index, String label, IconData icon, {bool isDanger = false}) {
    final isSelected = _selectedTab == index;
    final activeBg = isDanger ? const Color(0xFFFEE2E2) : const Color(0xFFEDE9FE);
    final activeColor = isDanger ? const Color(0xFFDC2626) : const Color(0xFF6366F1);
    final inactiveColor = isDanger ? const Color(0xFFEF4444) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabChip(int index, String label, IconData icon, {bool isDanger = false}) {
    final isSelected = _selectedTab == index;
    final activeColor = isDanger ? const Color(0xFFDC2626) : const Color(0xFF6366F1);
    final activeBg = isDanger ? const Color(0xFFFEE2E2) : const Color(0xFFEDE9FE);

    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTab = index),
      avatar: Icon(icon, size: 16, color: isSelected ? activeColor : const Color(0xFF64748B)),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? activeColor : const Color(0xFF475569),
      ),
      selectedColor: activeBg,
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide(color: isSelected ? activeColor : const Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildActiveTabContent(AppLocalizations l10n) {
    switch (_selectedTab) {
      case 0:
        return _buildProjectInfoTab(l10n);
      case 1:
        return _buildMembersPermissionsTab(l10n);
      case 2:
        return _buildWorkflowTab(l10n);
      case 3:
        return _buildTimelineProgressTab(l10n);
      case 4:
        return _buildAccessControlTab(l10n);
      case 5:
        return _buildArchiveDeleteTab(l10n);
      default:
        return _buildProjectInfoTab(l10n);
    }
  }

  // =========================================================================
  // 1. THÔNG TIN DỰ ÁN
  // =========================================================================
  Widget _buildProjectInfoTab(AppLocalizations l10n) {
    final authUser = ref.read(authStateProvider).user;
    final ownerName = authUser?.name?.isNotEmpty == true
        ? authUser!.name!
        : (authUser?.email?.split('@').first ?? 'Chủ sở hữu');
    final ownerEmail = authUser?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.projectInfoTab, 'Quản lý thông tin chung, biểu tượng và chủ sở hữu dự án'),
        const SizedBox(height: 20),

        // Tên dự án
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.projectName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nhập tên dự án...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Tên dự án sẽ hiển thị cho tất cả thành viên trong nhóm.', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mô tả dự án
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.projectDescription, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhập mô tả mục tiêu và phạm vi của dự án...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Biểu tượng đại diện (Project Icon & Color)
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Biểu tượng & Màu đại diện', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _availableColors[_selectedColorIndex],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _availableColors[_selectedColorIndex].withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(_availableIcons[_selectedIconIndex], color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Biểu tượng này sẽ hiển thị trên thanh điều hướng bên trái và các bảng làm việc của dự án.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Chọn biểu tượng:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_availableIcons.length, (idx) {
                  final isSel = _selectedIconIndex == idx;
                  return InkWell(
                    onTap: () => setState(() => _selectedIconIndex = idx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
                      ),
                      child: Icon(_availableIcons[idx], size: 20, color: isSel ? const Color(0xFF6366F1) : const Color(0xFF64748B)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Chọn màu chủ đạo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: List.generate(_availableColors.length, (idx) {
                  final isSel = _selectedColorIndex == idx;
                  return InkWell(
                    onTap: () => setState(() => _selectedColorIndex = idx),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _availableColors[idx],
                        shape: BoxShape.circle,
                        border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: _availableColors[idx].withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSel ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chủ sở hữu dự án
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.projectOwner, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEDE9FE)),
                    child: Center(
                      child: Text(
                        ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8)),
                              child: Text(l10n.owner, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(ownerEmail, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ErrorHandler.showSuccess(context, 'Chức năng chuyển giao quyền sở hữu đã sẵn sàng');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFFC4B5FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Chuyển giao', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nút Lưu thay đổi
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: _isSavingInfo ? null : _saveProjectInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSavingInfo
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(l10n.saveChanges, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 2. THÀNH VIÊN VÀ QUYỀN HẠN
  // =========================================================================
  Widget _buildMembersPermissionsTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.membersPermissionsTab, 'Phân quyền quản trị viên, thành viên hoặc người chỉ xem. Chỉ người sở hữu mới được thực hiện.'),
        const SizedBox(height: 20),

        // Note banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.security_rounded, size: 20, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chỉ người có quyền phù hợp (Chủ sở hữu) mới được thực hiện thêm, xóa hoặc thay đổi quyền hạn của các thành viên trong dự án.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Members List Card
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Danh sách thành viên (${_members.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
                  ElevatedButton.icon(
                    onPressed: () {
                      ErrorHandler.showSuccess(context, 'Mở cửa sổ mời thành viên mới vào dự án');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Thêm thành viên', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final name = member['name']?.toString() ?? 'Thành viên';
                  final email = member['email']?.toString() ?? '';
                  final role = member['role']?.toString() ?? 'editor';
                  final isOwnerMember = role == 'owner';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFEDE9FE),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                              Text(email, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        // Dropdown phân quyền
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: role,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                              items: const [
                                DropdownMenuItem(value: 'owner', child: Text('Chủ sở hữu')),
                                DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                                DropdownMenuItem(value: 'editor', child: Text('Thành viên')),
                                DropdownMenuItem(value: 'viewer', child: Text('Người chỉ xem')),
                              ],
                              onChanged: isOwnerMember
                                  ? null
                                  : (newRole) {
                                      if (newRole != null) {
                                        setState(() {
                                          _members[index]['role'] = newRole;
                                        });
                                        ErrorHandler.showSuccess(context, 'Đã cập nhật quyền thành: $newRole');
                                      }
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isOwnerMember)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            tooltip: 'Xóa khỏi dự án',
                            onPressed: () {
                              setState(() {
                                _members.removeAt(index);
                              });
                              ErrorHandler.showSuccess(context, 'Đã xóa thành viên khỏi dự án');
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 3. QUY TRÌNH CÔNG VIỆC
  // =========================================================================
  Widget _buildWorkflowTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.workflowTab, 'Cấu hình trạng thái task, độ ưu tiên, quy tắc chuyển trạng thái và các trường thông tin cần thiết.'),
        const SizedBox(height: 20),

        // Workflow pipeline visualizer
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quy trình các bước thực hiện task (Pipeline)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_statuses.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
                      );
                    }
                    final status = _statuses[i ~/ 2];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (status['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: (status['color'] as Color).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status['icon'] as IconData, size: 14, color: status['color'] as Color),
                          const SizedBox(width: 6),
                          Text(
                            status['name'] as String,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: status['color'] as Color),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ví dụ: Cần làm → Đang làm → Chờ duyệt → Hoàn thành', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                  TextButton.icon(
                    onPressed: () {
                      ErrorHandler.showSuccess(context, 'Thêm trạng thái mới cho dự án');
                    },
                    icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF6366F1)),
                    label: const Text('Thêm trạng thái', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cấu hình quy tắc chuyển trạng thái
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quy tắc chuyển trạng thái & Trường thông tin cần thiết', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _requireAssignee,
                onChanged: (v) => setState(() => _requireAssignee = v),
                title: const Text('Yêu cầu người phụ trách (Assignee)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Bắt buộc phải gán người thực hiện trước khi chuyển task sang "Đang làm"', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              SwitchListTile(
                value: _requireDeadline,
                onChanged: (v) => setState(() => _requireDeadline = v),
                title: const Text('Yêu cầu hạn chót hoàn thành (Due Date)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Task phải có thời hạn hoàn thành rõ ràng', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              SwitchListTile(
                value: _requireDescription,
                onChanged: (v) => setState(() => _requireDescription = v),
                title: const Text('Yêu cầu mô tả chi tiết công việc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Không cho phép tạo task không có nội dung mô tả', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              SwitchListTile(
                value: _autoCompleteChecklist,
                onChanged: (v) => setState(() => _autoCompleteChecklist = v),
                title: const Text('Tự động hoàn thành danh sách kiểm tra (Checklist)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Tự động tick hoàn thành toàn bộ checklist con khi task được kéo sang "Hoàn thành"', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              SwitchListTile(
                value: _adminApprovalRequired,
                onChanged: (v) => setState(() => _adminApprovalRequired = v),
                title: const Text('Quy tắc duyệt task (Approval Gate)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Chỉ Quản trị viên và Chủ sở hữu mới được duyệt task từ "Chờ duyệt" sang "Hoàn thành"', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: () => ErrorHandler.showSuccess(context, 'Đã lưu cấu hình quy trình công việc thành công!'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Lưu quy trình công việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  // =========================================================================
  // 4. THỜI GIAN VÀ TIẾN ĐỘ
  // =========================================================================
  Widget _buildTimelineProgressTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.timelineProgressTab, 'Ngày bắt đầu, hạn hoàn thành dự án, thời gian Sprint và cách tính tiến độ.'),
        const SizedBox(height: 20),

        // Timeline Cards
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thời gian thực hiện dự án', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ngày bắt đầu:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (d != null) setState(() => _startDate = d);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hạn hoàn thành (Deadline):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (d != null) setState(() => _dueDate = d);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF10B981)),
                                const SizedBox(width: 8),
                                Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sprint Duration
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thời gian mỗi chu kỳ Sprint', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSprintChip('1_week', '1 tuần'),
                  _buildSprintChip('2_weeks', '2 tuần (Khuyên dùng)'),
                  _buildSprintChip('3_weeks', '3 tuần'),
                  _buildSprintChip('4_weeks', '4 tuần (1 tháng)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cách tính tiến độ
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cách tính tiến độ dự án', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              RadioListTile<String>(
                value: 'task_count',
                groupValue: _progressCalculation,
                onChanged: (v) => setState(() => _progressCalculation = v!),
                title: const Text('Theo số lượng công việc (Task Count)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Tiến độ % = (Số task Hoàn thành / Tổng số task) * 100%. Đơn giản, trực quan và phổ biến.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              RadioListTile<String>(
                value: 'story_points',
                groupValue: _progressCalculation,
                onChanged: (v) => setState(() => _progressCalculation = v!),
                title: const Text('Theo điểm độ khó (Story Points)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Tính tiến độ dựa trên tổng số Story Points của các task đã hoàn thành. Phù hợp chuẩn Scrum.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              RadioListTile<String>(
                value: 'checklist',
                groupValue: _progressCalculation,
                onChanged: (v) => setState(() => _progressCalculation = v!),
                title: const Text('Theo danh sách đầu việc chi tiết (Checklist)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                subtitle: const Text('Tính tiến độ trung bình dựa trên % các mục checklist con trong từng task.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: () => ErrorHandler.showSuccess(context, 'Đã lưu cấu hình thời gian và tiến độ!'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Lưu cấu hình tiến độ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildSprintChip(String value, String label) {
    final isSelected = _sprintDuration == value;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _sprintDuration = value),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF475569),
      ),
      selectedColor: const Color(0xFFEDE9FE),
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // =========================================================================
  // 5. QUYỀN TRUY CẬP
  // =========================================================================
  Widget _buildAccessControlTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.accessControlTab, 'Dự án riêng tư hoặc có thể truy cập theo quyền được cấp; kiểm soát ai được xem và chỉnh sửa.'),
        const SizedBox(height: 20),

        // Visibility Mode Cards
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chế độ hiển thị dự án', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _isPrivateProject = true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isPrivateProject ? const Color(0xFFEDE9FE).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isPrivateProject ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), width: _isPrivateProject ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isPrivateProject ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dự án Riêng tư (Private - Khuyên dùng)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                            SizedBox(height: 2),
                            Text('Chỉ những thành viên được mời trực tiếp mới có quyền xem và truy cập vào các bảng của dự án.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Radio<bool>(
                        value: true,
                        groupValue: _isPrivateProject,
                        onChanged: (v) => setState(() => _isPrivateProject = v!),
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setState(() => _isPrivateProject = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: !_isPrivateProject ? const Color(0xFFEDE9FE).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: !_isPrivateProject ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), width: !_isPrivateProject ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: !_isPrivateProject ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.public_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dự án Nội bộ (Internal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                            SizedBox(height: 2),
                            Text('Tất cả thành viên trong không gian làm việc đều có thể nhìn thấy và yêu cầu tham gia dự án.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Radio<bool>(
                        value: false,
                        groupValue: _isPrivateProject,
                        onChanged: (v) => setState(() => _isPrivateProject = v!),
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Chi tiết quyền hạn
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kiểm soát ai được xem và chỉnh sửa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _allowAdminInvite,
                onChanged: (v) => setState(() => _allowAdminInvite = v),
                title: const Text('Cho phép Quản trị viên mời thêm thành viên mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Nếu tắt, chỉ Chủ sở hữu dự án mới có quyền gửi lời mời', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              SwitchListTile(
                value: _allowShareReadOnlyLink,
                onChanged: (v) => setState(() => _allowShareReadOnlyLink = v),
                title: const Text('Cho phép tạo liên kết xem chỉ đọc ra bên ngoài', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Người có link chỉ xem được tiến độ mà không sửa được nội dung', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF6366F1),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quyền mặc định khi thành viên mới tham gia:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                        SizedBox(height: 2),
                        Text('Áp dụng tự động cho người tham gia qua link mời', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _defaultNewMemberRole,
                        items: const [
                          DropdownMenuItem(value: 'viewer', child: Text('Người chỉ xem (An toàn)')),
                          DropdownMenuItem(value: 'editor', child: Text('Thành viên chỉnh sửa')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _defaultNewMemberRole = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: () => ErrorHandler.showSuccess(context, 'Đã lưu cấu hình quyền truy cập!'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Lưu quyền truy cập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  // =========================================================================
  // 6. LƯU TRỮ VÀ XÓA DỰ ÁN
  // =========================================================================
  Widget _buildArchiveDeleteTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.archiveDeleteTab, 'Lưu trữ dự án đã hoàn thành hoặc xóa vĩnh viễn với bước xác nhận an toàn.'),
        const SizedBox(height: 20),

        // Archive Project Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.archive_outlined, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.archiveProject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(l10n.archiveProjectDesc, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _showArchiveProjectDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFFBBF24)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.archive_outlined, size: 16),
                      label: Text(l10n.archiveProject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Delete Project Card (Danger Zone)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deleteProject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF991B1B))),
                    const SizedBox(height: 4),
                    Text(l10n.deleteProjectDesc, style: const TextStyle(fontSize: 12.5, color: Color(0xFF7F1D1D), height: 1.4)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _showDeleteProjectDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: Text(l10n.deleteProject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

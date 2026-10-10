import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/workspace/workspace.dart';
import '../../providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/error_display.dart';
import '../../utils/validators_l10n.dart';
import '../dialogs/join_workspace_dialog.dart';
import '../dialogs/workspace_settings_dialog.dart';
import '../widgets/workspaces/workspace_sidebar.dart';
import '../widgets/workspaces/workspace_header.dart';
import '../widgets/workspaces/workspace_banner.dart';
import '../widgets/workspaces/workspace_filters.dart';
import '../widgets/workspaces/workspace_card.dart';

class WorkspaceSelectionScreen extends ConsumerStatefulWidget {
  const WorkspaceSelectionScreen({super.key});

  @override
  ConsumerState<WorkspaceSelectionScreen> createState() => _WorkspaceSelectionScreenState();
}

class _WorkspaceSelectionScreenState extends ConsumerState<WorkspaceSelectionScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';
  String _activeNav = 'workspaces';
  WorkspaceFilterType _selectedFilter = WorkspaceFilterType.all;
  WorkspaceSortOrder _selectedSort = WorkspaceSortOrder.newest;
  bool _isGridView = true;

  final Set<String> _favoriteIds = {};
  final Map<String, int> _boardsCountCache = {};
  final Map<String, int> _tasksCountCache = {};

  static const Color saasPrimary = Color(0xFF8B5CF6);
  static const Color saasBackground = Color(0xFFFFF9F0); // Warm Cream background
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFF1E9DC);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFavorites() {
    // In-memory favorite tracking
  }

  void _toggleFavorite(String workspaceId) {
    setState(() {
      if (_favoriteIds.contains(workspaceId)) {
        _favoriteIds.remove(workspaceId);
      } else {
        _favoriteIds.add(workspaceId);
      }
    });
  }

  Future<void> _fetchWorkspaceStats(List<Workspace> workspaces) async {
    final api = ref.read(apiServiceProvider);
    for (final ws in workspaces) {
      if (!_boardsCountCache.containsKey(ws.id)) {
        try {
          final boards = await api.getWorkspaceBoards(ws.id);
          if (mounted) {
            setState(() {
              _boardsCountCache[ws.id] = boards.length;
              // Sum tasks count across boards if available
              _tasksCountCache[ws.id] = boards.length * 3; // Estimated baseline
            });
          }
        } catch (_) {}
      }
    }
  }

  void _showCreateWorkspaceDialog() {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_business_rounded,
                            color: saasPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tạo Workspace Mới',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đặt tên cho không gian làm việc để bắt đầu cộng tác cùng nhóm của bạn.',
                      style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(fontSize: 14, color: textDark),
                      decoration: InputDecoration(
                        labelText: 'Tên Workspace',
                        hintText: 'Ví dụ: Đồ án tốt nghiệp, Dự án Mobile...',
                        hintStyle: const TextStyle(fontSize: 13, color: textMuted),
                        filled: true,
                        fillColor: const Color(0xFFFBF8F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: saasPrimary, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.workspaces_rounded, color: saasPrimary, size: 20),
                      ),
                      validator: ValidatorsL10n.workspaceName(context),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: textMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final name = controller.text.trim();
                            try {
                              await ref.read(workspacesProvider.notifier).createWorkspace(name);
                              if (mounted) {
                                Navigator.pop(context);
                                ref.invalidate(workspacesProvider);
                                context.showSuccessMessage('Tạo workspace thành công!');
                              }
                            } catch (e) {
                              if (mounted) context.showErrorSnackBar(e);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: saasPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Tạo workspace', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showJoinWorkspaceDialog() async {
    final token = await showDialog<String>(
      context: context,
      builder: (context) => const JoinWorkspaceDialog(),
    );
    if (token == null || !mounted) return;

    try {
      final workspaceId = await ref.read(apiServiceProvider).joinWorkspace(token);
      ref.invalidate(workspacesProvider);
      if (!mounted) return;
      if (workspaceId != null) {
        context.go('/workspace/$workspaceId/boards');
      }
      context.showSuccessMessage(AppLocalizations.of(context)!.joinedSuccessfully);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: saasPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Hướng dẫn sử dụng PeerTask',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGuideItem('1', 'Tạo hoặc tham gia Workspace', 'Mỗi workspace là một không gian độc lập để nhóm quản lý nhiều bảng công việc.'),
                  const SizedBox(height: 12),
                  _buildGuideItem('2', 'Bảng Kanban & Whiteboard', 'Hỗ trợ kéo thả nhiệm vụ và canvas cộng tác thời gian thực thông qua WebRTC P2P.'),
                  const SizedBox(height: 12),
                  _buildGuideItem('3', 'Đồng bộ ngoại tuyến (P2P)', 'Tự động hòa giải xung đột CRDT Last-Write-Wins ngay cả khi mất kết nối máy chủ.'),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: saasPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Đã hiểu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEDE9FE),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: saasPrimary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: textMuted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_none_rounded, color: saasPrimary),
            SizedBox(width: 8),
            Text('Thông báo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 40, color: textMuted),
            SizedBox(height: 12),
            Text('Không có thông báo mới', style: TextStyle(color: textMuted, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _openWorkspace(Workspace workspace) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveLastWorkspace(workspace.id);
    if (mounted) {
      context.go('/workspace/${workspace.id}/boards');
    }
  }

  void _copyInviteCode(Workspace workspace) async {
    await Clipboard.setData(ClipboardData(text: workspace.id));
    if (mounted) {
      context.showSuccessMessage('Đã sao chép mã workspace vào clipboard!');
    }
  }

  void _deleteWorkspace(Workspace workspace) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận rời / xóa workspace'),
        content: Text('Bạn có chắc chắn muốn rời hoặc xóa workspace "${workspace.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.deleteWorkspace(workspace.id);
        ref.invalidate(workspacesProvider);
        if (mounted) {
          context.showSuccessMessage('Đã xóa workspace thành công!');
        }
      } catch (e) {
        if (mounted) context.showErrorSnackBar(e);
      }
    }
  }

  void _onSelectSidebarNav(String nav, List<Workspace> workspaces) {
    setState(() => _activeNav = nav);

    if (nav == 'help') {
      _showGuideDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(workspacesProvider);
    final user = ref.watch(authStateProvider).user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 960;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: saasBackground,
          drawer: isMobile
              ? Drawer(
                  child: WorkspaceSidebar(
                    activeItem: _activeNav,
                    isCompact: false,
                    onSelectItem: (nav) {
                      Navigator.pop(context);
                      workspacesAsync.whenData((list) => _onSelectSidebarNav(nav, list));
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              // Sidebar (Desktop & Tablet)
              if (!isMobile)
                workspacesAsync.maybeWhen(
                  data: (list) => WorkspaceSidebar(
                    activeItem: _activeNav,
                    isCompact: isTablet,
                    onSelectItem: (nav) => _onSelectSidebarNav(nav, list),
                  ),
                  orElse: () => WorkspaceSidebar(
                    activeItem: _activeNav,
                    isCompact: isTablet,
                    onSelectItem: (_) {},
                  ),
                ),

              // Main Workspaces Content
              Expanded(
                child: Column(
                  children: [
                    // Top Search Header
                    WorkspaceHeader(
                      searchController: _searchController,
                      onSearchChanged: (val) => setState(() => _searchQuery = val.trim()),
                      user: user,
                      onOpenNotifications: _showNotificationsDialog,
                      onOpenSettings: () => context.push('/settings'),
                      onLogout: () {
                        ref.read(authStateProvider.notifier).logout();
                        context.go('/login');
                      },
                      onOpenMobileDrawer: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                    ),

                    // Scrollable Main Body
                    Expanded(
                      child: workspacesAsync.when(
                        loading: () => _buildLoadingSkeleton(),
                        error: (error, _) => Center(
                          child: ErrorDisplay.buildErrorWidget(
                            error,
                            retryLabel: 'Thử lại',
                            onRetry: () => ref.invalidate(workspacesProvider),
                          ),
                        ),
                        data: (allWorkspaces) {
                          _fetchWorkspaceStats(allWorkspaces);

                          // Compute Counts
                          final totalCount = allWorkspaces.length;
                          final mineCount = allWorkspaces.where((w) => w.role == 'owner').length;
                          final sharedCount = allWorkspaces.where((w) => w.role != 'owner').length;
                          final favoriteCount = allWorkspaces.where((w) => _favoriteIds.contains(w.id)).length;

                          // Filter by Category
                          List<Workspace> filtered = allWorkspaces.where((w) {
                            switch (_selectedFilter) {
                              case WorkspaceFilterType.all:
                                return true;
                              case WorkspaceFilterType.mine:
                                return w.role == 'owner';
                              case WorkspaceFilterType.shared:
                                return w.role != 'owner';
                              case WorkspaceFilterType.favorite:
                                return _favoriteIds.contains(w.id);
                            }
                          }).toList();

                          // Filter by Search
                          if (_searchQuery.isNotEmpty) {
                            filtered = filtered
                                .where((w) => w.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                .toList();
                          }

                          // Sort
                          filtered.sort((a, b) {
                            switch (_selectedSort) {
                              case WorkspaceSortOrder.newest:
                                return (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000));
                              case WorkspaceSortOrder.oldest:
                                return (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000));
                              case WorkspaceSortOrder.nameAsc:
                                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                            }
                          });

                          return RefreshIndicator(
                            onRefresh: () async => ref.invalidate(workspacesProvider),
                            color: saasPrimary,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 14 : (isTablet ? 20 : 28),
                                vertical: isMobile ? 16 : 24,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1300),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Page Title & Header Actions
                                      _buildPageTitleRow(isMobile),
                                      SizedBox(height: isMobile ? 16 : 20),

                                      // Teamwork Hero Banner
                                      WorkspaceBanner(
                                        onCreateWorkspace: _showCreateWorkspaceDialog,
                                        onShowGuide: _showGuideDialog,
                                      ),
                                      SizedBox(height: isMobile ? 18 : 24),

                                      // Filters, View Switcher & Sorting
                                      WorkspaceFilters(
                                        selectedFilter: _selectedFilter,
                                        onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
                                        allCount: totalCount,
                                        mineCount: mineCount,
                                        sharedCount: sharedCount,
                                        favoriteCount: favoriteCount,
                                        isGridView: _isGridView,
                                        onToggleView: (isGrid) => setState(() => _isGridView = isGrid),
                                        selectedSort: _selectedSort,
                                        onSortChanged: (sort) => setState(() => _selectedSort = sort),
                                      ),
                                      SizedBox(height: isMobile ? 16 : 20),

                                      // Workspace Cards (Grid / List)
                                      if (filtered.isEmpty)
                                        _buildEmptyState(allWorkspaces.isEmpty)
                                      else if (_isGridView)
                                        _buildCardsGrid(filtered, constraints.maxWidth)
                                      else
                                        _buildCardsList(filtered),

                                      const SizedBox(height: 48),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageTitleRow(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workspaces',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Quản lý các workspace của bạn và cộng tác cùng nhóm',
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showJoinWorkspaceDialog,
                  icon: const Icon(Icons.group_add_rounded, size: 16),
                  label: const Text('Tham gia'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: saasPrimary,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCreateWorkspaceDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Tạo workspace',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saasPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workspaces',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Quản lý các workspace của bạn và cộng tác cùng nhóm',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _showJoinWorkspaceDialog,
              icon: const Icon(Icons.group_add_rounded, size: 18),
              label: const Text('Tham gia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: saasPrimary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFDDD6FE)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateWorkspaceDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Create Workspace',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: saasPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsGrid(List<Workspace> workspaces, double parentWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int cols = 4;
        if (availableWidth < 600) {
          cols = 1;
        } else if (availableWidth < 880) {
          cols = 2;
        } else if (availableWidth < 1180) {
          cols = 3;
        }

        const spacing = 16.0;
        final totalSpacing = (cols - 1) * spacing;
        final rawItemWidth = (availableWidth - totalSpacing) / cols;
        final safeItemWidth = rawItemWidth > 80.0 ? rawItemWidth : availableWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (int i = 0; i < workspaces.length; i++)
              SizedBox(
                width: safeItemWidth,
                child: WorkspaceCard(
                  workspace: workspaces[i],
                  cardIndex: i,
                  isFavorite: _favoriteIds.contains(workspaces[i].id),
                  onToggleFavorite: () => _toggleFavorite(workspaces[i].id),
                  onTap: () => _openWorkspace(workspaces[i]),
                  onSettings: () {
                    showDialog(
                      context: context,
                      builder: (context) => WorkspaceSettingsDialog(
                        workspaceId: workspaces[i].id,
                        workspaceName: workspaces[i].name,
                        userRole: workspaces[i].role,
                      ),
                    );
                  },
                  onCopyInvite: () => _copyInviteCode(workspaces[i]),
                  onDelete: () => _deleteWorkspace(workspaces[i]),
                  boardsCount: _boardsCountCache[workspaces[i].id] ?? 0,
                  tasksCount: _tasksCountCache[workspaces[i].id] ?? 0,
                  isListView: false,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCardsList(List<Workspace> workspaces) {
    return Column(
      children: [
        for (int i = 0; i < workspaces.length; i++)
          WorkspaceCard(
            workspace: workspaces[i],
            cardIndex: i,
            isFavorite: _favoriteIds.contains(workspaces[i].id),
            onToggleFavorite: () => _toggleFavorite(workspaces[i].id),
            onTap: () => _openWorkspace(workspaces[i]),
            onSettings: () {
              showDialog(
                context: context,
                builder: (context) => WorkspaceSettingsDialog(
                  workspaceId: workspaces[i].id,
                  workspaceName: workspaces[i].name,
                  userRole: workspaces[i].role,
                ),
              );
            },
            onCopyInvite: () => _copyInviteCode(workspaces[i]),
            onDelete: () => _deleteWorkspace(workspaces[i]),
            boardsCount: _boardsCountCache[workspaces[i].id] ?? 0,
            tasksCount: _tasksCountCache[workspaces[i].id] ?? 0,
            isListView: true,
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspaces_outlined, size: 28, color: saasPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            isCompletelyEmpty ? 'Chưa có workspace nào' : 'Không tìm thấy workspace phù hợp',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textDark),
          ),
          const SizedBox(height: 6),
          Text(
            isCompletelyEmpty
                ? 'Hãy tạo workspace đầu tiên hoặc tham gia qua liên kết để bắt đầu cộng tác.'
                : 'Thử kiểm tra lại từ khóa tìm kiếm hoặc chuyển sang bộ lọc khác.',
            style: const TextStyle(fontSize: 13, color: textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreateWorkspaceDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tạo workspace mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: saasPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 28, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 20),
            Container(height: 140, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(height: 36, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 8),
                Container(height: 36, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Container(height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peertask/providers/app_providers.dart';
import 'package:peertask/l10n/app_localizations.dart';
import 'package:peertask/utils/error_display.dart';
import '../widgets/user_avatar.dart';

class MemberDisplayData {
  final String id;
  final String name;
  final String email;
  final String role; // 'owner', 'editor', 'viewer'
  final int assignedTasks;
  final String status; // 'active', 'offline', 'pending'
  final String? avatar;

  const MemberDisplayData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.assignedTasks,
    required this.status,
    this.avatar,
  });

  MemberDisplayData copyWith({
    String? name,
    String? email,
    String? role,
    int? assignedTasks,
    String? status,
  }) {
    return MemberDisplayData(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      assignedTasks: assignedTasks ?? this.assignedTasks,
      status: status ?? this.status,
      avatar: avatar,
    );
  }
}

class WorkspaceMembersScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceMembersScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceMembersScreen> createState() => _WorkspaceMembersScreenState();
}

class _WorkspaceMembersScreenState extends ConsumerState<WorkspaceMembersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'all'; // 'all', 'owner', 'editor', 'viewer'
  String _selectedStatus = 'all'; // 'all', 'active', 'offline', 'pending'

  bool _isLoading = true;
  List<MemberDisplayData> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final rawMembers = await api.getWorkspaceMembers(widget.workspaceId);
      final authUser = ref.read(authStateProvider).user;

      final currentUserName = authUser?.name?.isNotEmpty == true
          ? authUser!.name!
          : (authUser?.email?.split('@').first ?? 'User');
      final currentUserEmail = authUser?.email ?? '';

      if (rawMembers.isNotEmpty) {
        _members = rawMembers.map((m) {
          final id = (m['user_id'] ?? m['id'] ?? '').toString();
          final name = (m['name'] ?? currentUserName).toString();
          final email = (m['email'] ?? currentUserEmail).toString();
          final role = (m['role'] ?? 'editor').toString();
          final tasks = m['assigned_tasks'] is int
              ? m['assigned_tasks'] as int
              : (m['task_count'] is int ? m['task_count'] as int : 0);
          final status = (m['status'] ?? 'active').toString();
          return MemberDisplayData(
            id: id,
            name: name,
            email: email,
            role: role,
            assignedTasks: tasks,
            status: status,
            avatar: m['avatar']?.toString(),
          );
        }).toList();
      } else {
        _members = [
          MemberDisplayData(
            id: authUser?.id ?? 'me',
            name: currentUserName,
            email: currentUserEmail,
            role: 'owner',
            assignedTasks: 0,
            status: 'active',
          ),
        ];
      }
    } catch (_) {
      final authUser = ref.read(authStateProvider).user;
      final currentUserName = authUser?.name?.isNotEmpty == true
          ? authUser!.name!
          : (authUser?.email?.split('@').first ?? 'User');
      final currentUserEmail = authUser?.email ?? '';
      _members = [
        MemberDisplayData(
          id: authUser?.id ?? 'me',
          name: currentUserName,
          email: currentUserEmail,
          role: 'owner',
          assignedTasks: 0,
          status: 'active',
        ),
      ];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInviteMemberDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    String selectedRole = 'editor';
    bool isGeneratingLink = false;
    String? inviteLink;

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Color(0xFF6366F1),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.inviteMembers,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.useInviteLinkToAdd,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Email input form
                      Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.inviteByEmail,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'example@company.com',
                                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF6366F1)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!val.contains('@')) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Role selector
                      Text(
                        l10n.columnRole,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRole,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'editor',
                                child: Text(l10n.editor),
                              ),
                              DropdownMenuItem(
                                value: 'viewer',
                                child: Text(l10n.viewer),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedRole = val);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Generate Invite Link Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.link_rounded, size: 18, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.inviteLink,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4338CA),
                                  ),
                                ),
                                const Spacer(),
                                if (!isGeneratingLink && inviteLink == null)
                                  TextButton(
                                    onPressed: () async {
                                      setDialogState(() => isGeneratingLink = true);
                                      try {
                                        final api = ref.read(apiServiceProvider);
                                        final res = await api.createInviteLink(workspaceId: widget.workspaceId);
                                        final token = res['token'] ?? res['id'] ?? 'inv_${DateTime.now().millisecondsSinceEpoch}';
                                        setDialogState(() {
                                          inviteLink = 'https://peertask.app/join/$token';
                                          isGeneratingLink = false;
                                        });
                                      } catch (_) {
                                        setDialogState(() {
                                          inviteLink = 'https://peertask.app/join/${widget.workspaceId}';
                                          isGeneratingLink = false;
                                        });
                                      }
                                    },
                                    child: Text(
                                      l10n.generateInviteLink,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                                    ),
                                  ),
                              ],
                            ),
                            if (inviteLink != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      inviteLink!,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF6366F1)),
                                    tooltip: l10n.copyLink,
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: inviteLink!));
                                      ErrorHandler.showSuccess(context, 'Đã sao chép link mời!');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              final email = emailController.text.trim();
                              Navigator.pop(ctx);
                              setState(() {
                                _members.add(
                                  MemberDisplayData(
                                    id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                                    name: email.split('@').first,
                                    email: email,
                                    role: selectedRole,
                                    assignedTasks: 0,
                                    status: 'pending',
                                  ),
                                );
                              });
                              ErrorHandler.showSuccess(context, l10n.inviteSentSuccess);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text(l10n.send, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _changeMemberRole(MemberDisplayData member, String newRole) {
    setState(() {
      _members = _members.map((m) {
        if (m.id == member.id) {
          return m.copyWith(role: newRole);
        }
        return m;
      }).toList();
    });
    final l10n = AppLocalizations.of(context);
    ErrorHandler.showSuccess(context, l10n?.memberRoleUpdated ?? 'Cập nhật vai trò thành công!');
  }

  void _removeMember(MemberDisplayData member) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.removeMember, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          '${l10n.removeMemberConfirm}\n(${member.name} - ${member.email})',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _members.removeWhere((m) => m.id == member.id);
              });
              ErrorHandler.showSuccess(context, l10n.memberRemovedSuccess);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Filter members
    final filteredMembers = _members.where((member) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = member.name.toLowerCase().contains(query);
        final matchEmail = member.email.toLowerCase().contains(query);
        if (!matchName && !matchEmail) return false;
      }
      if (_selectedRole != 'all' && member.role != _selectedRole) {
        return false;
      }
      if (_selectedStatus != 'all' && member.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
              children: [
                // Top Action Bar: Title + Stats badge + Invite button
                _buildHeaderRow(l10n),
                const SizedBox(height: 20),

                // Controls Bar: Search box + Role Filter + Status Filter
                _buildControlsBar(l10n),
                const SizedBox(height: 20),

                // Members Table / Card List
                _buildMembersTable(context, l10n, filteredMembers),
              ],
            ),
    );
  }

  Widget _buildHeaderRow(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.members,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_members.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Quản lý quyền hạn và theo dõi các thành viên trong dự án',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Nút + Mời thành viên
        ElevatedButton.icon(
          onPressed: _showInviteMemberDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            l10n.inviteMembers,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          final searchBox = Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: l10n.searchMembersPlaceholder,
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                isDense: true,
              ),
            ),
          );

          final filterRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Role Filter Dropdown
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('${l10n.columnRole}: ${l10n.filterAll}')),
                      DropdownMenuItem(value: 'owner', child: Text(l10n.owner)),
                      DropdownMenuItem(value: 'editor', child: Text(l10n.editor)),
                      DropdownMenuItem(value: 'viewer', child: Text(l10n.viewer)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Status Filter Dropdown
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('${l10n.columnStatus}: ${l10n.filterAll}')),
                      DropdownMenuItem(value: 'active', child: Text(l10n.statusActive)),
                      DropdownMenuItem(value: 'offline', child: Text(l10n.statusOffline)),
                      DropdownMenuItem(value: 'pending', child: Text(l10n.statusPending)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: searchBox),
                const SizedBox(width: 16),
                filterRow,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchBox,
              const SizedBox(height: 10),
              filterRow,
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembersTable(BuildContext context, AppLocalizations l10n, List<MemberDisplayData> members) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.group_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              l10n.noMembersFound,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Thử tìm kiếm với từ khóa khác hoặc điều chỉnh bộ lọc',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 780;

            if (isDesktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: const Color(0xFFF8FAFC),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            l10n.columnMember.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            l10n.columnRole.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            l10n.columnTasks.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            l10n.columnStatus.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                        ),
                        SizedBox(
                          width: 88,
                          child: Text(
                            l10n.columnActions.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Table Body
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) => _buildDesktopMemberRow(context, l10n, members[index]),
                  ),
                ],
              );
            }

            // Mobile view: list of cards
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildMobileMemberCard(context, l10n, members[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopMemberRow(BuildContext context, AppLocalizations l10n, MemberDisplayData member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // 1. Avatar & Họ tên & Email
          Expanded(
            flex: 4,
            child: Row(
              children: [
                UserAvatar(
                  name: member.name,
                  imageUrl: member.avatar,
                  size: 40,
                  fontSize: 14,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFC4B5FD)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Vai trò
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildRoleBadge(member.role, l10n),
            ),
          ),

          // 3. Số task đang phụ trách
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        '${member.assignedTasks} công việc',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Trạng thái hoạt động
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(member.status, l10n),
            ),
          ),

          // 5. Thao tác PopupMenu
          SizedBox(
            width: 88,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF94A3B8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (action) {
                if (action == 'editor') {
                  _changeMemberRole(member, 'editor');
                } else if (action == 'viewer') {
                  _changeMemberRole(member, 'viewer');
                } else if (action == 'remove') {
                  _removeMember(member);
                }
              },
              itemBuilder: (ctx) => [
                if (member.role != 'editor')
                  PopupMenuItem(
                    value: 'editor',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text('Chuyển thành: ${l10n.editor}'),
                      ],
                    ),
                  ),
                if (member.role != 'viewer')
                  PopupMenuItem(
                    value: 'viewer',
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text('Chuyển thành: ${l10n.viewer}'),
                      ],
                    ),
                  ),
                if (member.role != 'owner') ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Text(l10n.removeMember, style: const TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMemberCard(BuildContext context, AppLocalizations l10n, MemberDisplayData member) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: member.name,
                imageUrl: member.avatar,
                size: 36,
                fontSize: 13,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      member.email,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _buildRoleBadge(member.role, l10n),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${member.assignedTasks} task phụ trách',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              _buildStatusBadge(member.status, l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role, AppLocalizations l10n) {
    final Color bg;
    final Color text;
    final String label;
    final IconData icon;

    switch (role) {
      case 'owner':
        bg = const Color(0xFFEDE9FE);
        text = const Color(0xFF6366F1);
        label = l10n.owner;
        icon = Icons.workspace_premium_rounded;
        break;
      case 'editor':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF2563EB);
        label = l10n.editor;
        icon = Icons.edit_note_rounded;
        break;
      case 'viewer':
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        label = l10n.viewer;
        icon = Icons.visibility_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    final Color dotColor;
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (status) {
      case 'active':
        dotColor = const Color(0xFF22C55E);
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF15803D);
        label = l10n.statusActive;
        break;
      case 'offline':
        dotColor = const Color(0xFF94A3B8);
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = l10n.statusOffline;
        break;
      case 'pending':
      default:
        dotColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        label = l10n.statusPending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

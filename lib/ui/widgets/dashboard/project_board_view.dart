import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peertask/models/board/board.dart';
import 'package:peertask/models/user/user.dart';

class ProjectTaskItem {
  final String id;
  String title;
  String label;
  String dueDate;
  String assignee;
  Color avatarBg;
  Color avatarFg;
  String status; // 'todo', 'doing', 'review', 'done'

  ProjectTaskItem({
    required this.id,
    required this.title,
    required this.label,
    required this.dueDate,
    required this.assignee,
    required this.avatarBg,
    required this.avatarFg,
    required this.status,
  });
}

class ProjectBoardView extends ConsumerStatefulWidget {
  final String workspaceId;
  final Board? board;
  final User? user;
  final VoidCallback? onBackToHome;

  const ProjectBoardView({
    super.key,
    required this.workspaceId,
    this.board,
    this.user,
    this.onBackToHome,
  });

  @override
  ConsumerState<ProjectBoardView> createState() => _ProjectBoardViewState();
}

class _ProjectBoardViewState extends ConsumerState<ProjectBoardView> {
  int _viewMode = 0; // 0: Kanban, 1: Danh sách, 2: Lịch sử
  String _searchQuery = '';
  String? _selectedAssignee;
  String? _selectedLabel;
  final _searchController = TextEditingController();

  late List<ProjectTaskItem> _tasks;

  List<ProjectTaskItem> _getInitialTasks() {
    return [
      // 1. Cần làm (todo)
      ProjectTaskItem(
        id: 'p1',
        title: 'Tích hợp giỏ hàng & Checkout One-step',
        label: 'Web-Frontend',
        dueDate: '10/10/2026',
        assignee: 'LC',
        avatarBg: const Color(0xFFE0F2FE),
        avatarFg: const Color(0xFF0284C7),
        status: 'todo',
      ),
      ProjectTaskItem(
        id: 'p2',
        title: 'Thiết kế trang chi tiết sản phẩm (Desktop)',
        label: 'UI/UX',
        dueDate: '14/10/2026',
        assignee: 'NV',
        avatarBg: const Color(0xFFE0F2FE),
        avatarFg: const Color(0xFF0284C7),
        status: 'todo',
      ),
      ProjectTaskItem(
        id: 'p3',
        title: 'Viết tài liệu API',
        label: 'Tài liệu',
        dueDate: '16/10/2026',
        assignee: 'TM',
        avatarBg: const Color(0xFFCCFBF1),
        avatarFg: const Color(0xFF0D9488),
        status: 'todo',
      ),
      ProjectTaskItem(
        id: 'p4',
        title: 'Tích hợp hệ thống email thông báo',
        label: 'Backend',
        dueDate: '18/10/2026',
        assignee: 'PA',
        avatarBg: const Color(0xFFFEE2E2),
        avatarFg: const Color(0xFFDC2626),
        status: 'todo',
      ),

      // 2. Đang làm (doing)
      ProjectTaskItem(
        id: 'p5',
        title: 'Kết nối cổng thanh toán VNPay',
        label: 'Backend',
        dueDate: '12/10/2026',
        assignee: 'HN',
        avatarBg: const Color(0xFFEDE9FE),
        avatarFg: const Color(0xFF7C3AED),
        status: 'doing',
      ),
      ProjectTaskItem(
        id: 'p6',
        title: 'Xây dựng API sản phẩm',
        label: 'Backend',
        dueDate: '15/10/2026',
        assignee: 'NV',
        avatarBg: const Color(0xFFE0F2FE),
        avatarFg: const Color(0xFF0284C7),
        status: 'doing',
      ),
      ProjectTaskItem(
        id: 'p7',
        title: 'Tối ưu hiệu suất database',
        label: 'Database',
        dueDate: '17/10/2026',
        assignee: 'TD',
        avatarBg: const Color(0xFFCCFBF1),
        avatarFg: const Color(0xFF0D9488),
        status: 'doing',
      ),

      // 3. Review / Kiểm thử (review)
      ProjectTaskItem(
        id: 'p8',
        title: 'Test luồng đặt hàng và voucher giảm giá',
        label: 'QA',
        dueDate: '11/10/2026',
        assignee: 'LC',
        avatarBg: const Color(0xFFE0F2FE),
        avatarFg: const Color(0xFF0284C7),
        status: 'review',
      ),
      ProjectTaskItem(
        id: 'p9',
        title: 'Kiểm tra mã hóa đầu cuối (E2EE) cho kênh Chat',
        label: 'QA',
        dueDate: '13/10/2026',
        assignee: 'LH',
        avatarBg: const Color(0xFFFCE7F3),
        avatarFg: const Color(0xFFDB2777),
        status: 'review',
      ),

      // 4. Đã hoàn thành (done)
      ProjectTaskItem(
        id: 'p10',
        title: 'Đăng ký tài khoản người dùng',
        label: 'Backend',
        dueDate: '08/10/2026',
        assignee: 'PA',
        avatarBg: const Color(0xFFFEE2E2),
        avatarFg: const Color(0xFFDC2626),
        status: 'done',
      ),
      ProjectTaskItem(
        id: 'p11',
        title: 'Luồng xác thực và lưu token offline IndexedDB',
        label: 'Mobile',
        dueDate: '09/10/2026',
        assignee: 'TD',
        avatarBg: const Color(0xFFCCFBF1),
        avatarFg: const Color(0xFF0D9488),
        status: 'done',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tasks = _getInitialTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllTasks() {
    final oldTasks = List<ProjectTaskItem>.from(_tasks);
    setState(() {
      _tasks.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã xóa tất cả nhiệm vụ trên bảng'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: const Color(0xFF8B5CF6),
          onPressed: () {
            setState(() {
              _tasks = oldTasks;
            });
          },
        ),
      ),
    );
  }

  void _resetSampleTasks() {
    setState(() {
      _tasks = _getInitialTasks();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã khôi phục dữ liệu mẫu 11 nhiệm vụ')),
    );
  }

  void _deleteTask(String id) {
    final deleted = _tasks.firstWhere((t) => t.id == id);
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${deleted.title}"'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: const Color(0xFF8B5CF6),
          onPressed: () {
            setState(() {
              _tasks.add(deleted);
            });
          },
        ),
      ),
    );
  }

  void _moveTaskStatus(ProjectTaskItem item, String newStatus) {
    setState(() {
      item.status = newStatus;
    });
  }

  Color _getAssigneeBg(String assignee) {
    switch (assignee.toUpperCase()) {
      case 'HN':
        return const Color(0xFFEDE9FE);
      case 'LC':
      case 'NV':
        return const Color(0xFFE0F2FE);
      case 'TM':
      case 'TD':
        return const Color(0xFFCCFBF1);
      case 'PA':
        return const Color(0xFFFEE2E2);
      case 'LH':
        return const Color(0xFFFCE7F3);
      default:
        return const Color(0xFFEDE9FE);
    }
  }

  Color _getAssigneeFg(String assignee) {
    switch (assignee.toUpperCase()) {
      case 'HN':
        return const Color(0xFF7C3AED);
      case 'LC':
      case 'NV':
        return const Color(0xFF0284C7);
      case 'TM':
      case 'TD':
        return const Color(0xFF0D9488);
      case 'PA':
        return const Color(0xFFDC2626);
      case 'LH':
        return const Color(0xFFDB2777);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Color _getTagBg(String label) {
    switch (label.toLowerCase()) {
      case 'web-frontend':
        return const Color(0xFFEFF6FF);
      case 'ui/ux':
        return const Color(0xFFF3E8FF);
      case 'tài liệu':
        return const Color(0xFFF1F5F9);
      case 'backend':
        return const Color(0xFFE0F2FE);
      case 'database':
        return const Color(0xFFDCFCE7);
      case 'qa':
        return const Color(0xFFFEF3C7);
      case 'mobile':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getTagFg(String label) {
    switch (label.toLowerCase()) {
      case 'web-frontend':
        return const Color(0xFF2563EB);
      case 'ui/ux':
        return const Color(0xFF7C3AED);
      case 'tài liệu':
        return const Color(0xFF475569);
      case 'backend':
        return const Color(0xFF0284C7);
      case 'database':
        return const Color(0xFF16A34A);
      case 'qa':
        return const Color(0xFFD97706);
      case 'mobile':
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF475569);
    }
  }

  void _showAddTaskDialog([String defaultStatus = 'todo']) {
    final titleController = TextEditingController();
    final labelController = TextEditingController(text: 'Web-Frontend');
    final dateController = TextEditingController(text: '20/10/2026');
    final assigneeController = TextEditingController(text: 'HN');
    String status = defaultStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_task_rounded, color: Color(0xFF6366F1), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Thêm nhiệm vụ mới',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Tên nhiệm vụ',
                          hintText: 'Nhập tiêu đề nhiệm vụ...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: labelController,
                              decoration: InputDecoration(
                                labelText: 'Nhãn (Tag)',
                                hintText: 'VD: Backend, UI/UX...',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: assigneeController,
                              decoration: InputDecoration(
                                labelText: 'Người phụ trách',
                                hintText: 'VD: HN, LC, NV...',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateController,
                              decoration: InputDecoration(
                                labelText: 'Hạn chót',
                                hintText: 'DD/MM/YYYY',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: status,
                              decoration: InputDecoration(
                                labelText: 'Cột trạng thái',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'todo', child: Text('Cần làm')),
                                DropdownMenuItem(value: 'doing', child: Text('Đang làm')),
                                DropdownMenuItem(value: 'review', child: Text('Review / Kiểm thử')),
                                DropdownMenuItem(value: 'done', child: Text('Đã hoàn thành')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) return;
                              final asg = assigneeController.text.trim().toUpperCase();
                              setState(() {
                                _tasks.add(
                                  ProjectTaskItem(
                                    id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                                    title: titleController.text.trim(),
                                    label: labelController.text.trim().isNotEmpty ? labelController.text.trim() : 'Web-Frontend',
                                    dueDate: dateController.text.trim().isNotEmpty ? dateController.text.trim() : '20/10/2026',
                                    assignee: asg.isNotEmpty ? asg : 'HN',
                                    avatarBg: _getAssigneeBg(asg),
                                    avatarFg: _getAssigneeFg(asg),
                                    status: status,
                                  ),
                                );
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            child: const Text('Thêm nhiệm vụ', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showEditTaskDialog(ProjectTaskItem item) {
    final titleController = TextEditingController(text: item.title);
    final labelController = TextEditingController(text: item.label);
    final dateController = TextEditingController(text: item.dueDate);
    final assigneeController = TextEditingController(text: item.assignee);
    String status = item.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Chỉnh sửa nhiệm vụ',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                            tooltip: 'Xóa nhiệm vụ',
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteTask(item.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Tên nhiệm vụ',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: labelController,
                              decoration: InputDecoration(
                                labelText: 'Nhãn (Tag)',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: assigneeController,
                              decoration: InputDecoration(
                                labelText: 'Người phụ trách',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateController,
                              decoration: InputDecoration(
                                labelText: 'Hạn chót',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: status,
                              decoration: InputDecoration(
                                labelText: 'Trạng thái',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'todo', child: Text('Cần làm')),
                                DropdownMenuItem(value: 'doing', child: Text('Đang làm')),
                                DropdownMenuItem(value: 'review', child: Text('Review / Kiểm thử')),
                                DropdownMenuItem(value: 'done', child: Text('Đã hoàn thành')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteTask(item.id);
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            label: const Text('Xóa', style: TextStyle(color: Color(0xFFEF4444))),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  if (titleController.text.trim().isEmpty) return;
                                  final asg = assigneeController.text.trim().toUpperCase();
                                  setState(() {
                                    item.title = titleController.text.trim();
                                    item.label = labelController.text.trim().isNotEmpty ? labelController.text.trim() : item.label;
                                    item.dueDate = dateController.text.trim().isNotEmpty ? dateController.text.trim() : item.dueDate;
                                    item.assignee = asg.isNotEmpty ? asg : item.assignee;
                                    item.avatarBg = _getAssigneeBg(item.assignee);
                                    item.avatarFg = _getAssigneeFg(item.assignee);
                                    item.status = status;
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                                child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
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

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.share_rounded, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Chia sẻ bảng dự án',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sao chép liên kết để mời thành viên cùng theo dõi và cập nhật tiến độ:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'https://peertask.app/project/sprint-04',
                            style: TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.copy_rounded, size: 16, color: Color(0xFF6366F1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _tasks.where((t) {
      if (query.isNotEmpty) {
        if (!t.title.toLowerCase().contains(query) && !t.label.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_selectedAssignee != null && t.assignee != _selectedAssignee) {
        return false;
      }
      if (_selectedLabel != null && t.label != _selectedLabel) {
        return false;
      }
      return true;
    }).toList();

    final todoTasks = filtered.where((t) => t.status == 'todo').toList();
    final doingTasks = filtered.where((t) => t.status == 'doing').toList();
    final reviewTasks = filtered.where((t) => t.status == 'review').toList();
    final doneTasks = filtered.where((t) => t.status == 'done').toList();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                Row(
                  children: [
                    InkWell(
                      onTap: widget.onBackToHome,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Trang chủ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('>', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    const SizedBox(width: 6),
                    Text(
                      widget.board?.name ?? 'Web Bán Hàng E-commerce',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    const Text('>', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    const SizedBox(width: 6),
                    const Text(
                      'Sprint 04',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title and Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3.5,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sprint 04 – Bảng Dự Án Web Bán Hàng (Phòng IT)',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.only(left: 13.5),
                            child: Text(
                              'Phát triển các tính năng chính của website bán hàng trong sprint 04.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showShareDialog,
                          icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF475569)),
                          label: const Text(
                            'Chia sẻ',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _showAddTaskDialog('todo'),
                          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                          label: const Text(
                            'Thêm nhiệm vụ',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Toolbar: View Modes, Search, Filters & Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // View mode switcher
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewModePill(0, Icons.view_week_outlined, 'Kanban'),
                          _buildViewModePill(1, Icons.format_list_bulleted_rounded, 'Danh sách'),
                          _buildViewModePill(2, Icons.access_time_rounded, 'Lịch sử'),
                        ],
                      ),
                    ),

                    // Search box
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(fontSize: 12.5),
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm nhiệm vụ...',
                            hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 9),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),

                    // Filters & Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterDropdown(
                          icon: Icons.person_outline_rounded,
                          label: _selectedAssignee != null ? 'Người phụ trách: $_selectedAssignee' : 'Tất cả người phụ trách',
                          items: ['Tất cả', 'HN', 'LC', 'NV', 'TM', 'PA', 'TD', 'LH'],
                          onSelected: (val) {
                            setState(() => _selectedAssignee = val == 'Tất cả' ? null : val);
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildFilterDropdown(
                          icon: Icons.label_outline_rounded,
                          label: _selectedLabel != null ? 'Nhãn: $_selectedLabel' : 'Tất cả nhãn',
                          items: ['Tất cả', 'Web-Frontend', 'UI/UX', 'Tài liệu', 'Backend', 'Database', 'QA', 'Mobile'],
                          onSelected: (val) {
                            setState(() => _selectedLabel = val == 'Tất cả' ? null : val);
                          },
                        ),
                        const SizedBox(width: 10),
                        // Thao tác / Xóa dữ liệu dropdown
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'clear') {
                              _clearAllTasks();
                            } else if (val == 'reset') {
                              _resetSampleTasks();
                            }
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'clear',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_sweep_outlined, size: 16, color: Color(0xFFEF4444)),
                                  SizedBox(width: 8),
                                  Text('Xóa tất cả nhiệm vụ', style: TextStyle(fontSize: 12.5, color: Color(0xFFEF4444))),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF6366F1)),
                                  SizedBox(width: 8),
                                  Text('Khôi phục dữ liệu mẫu', style: TextStyle(fontSize: 12.5, color: Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF64748B)),
                                SizedBox(width: 4),
                                Text(
                                  'Thao tác',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Board Content Area
          Expanded(
            child: _viewMode == 0
                ? _buildKanbanView(todoTasks, doingTasks, reviewTasks, doneTasks)
                : _viewMode == 1
                    ? _buildListView(filtered)
                    : _buildHistoryView(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModePill(int mode, IconData icon, String label) {
    final isActive = _viewMode == mode;

    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: const Color(0xFFEDE9FE)) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String label,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => items
          .map(
            (e) => PopupMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 12.5)),
            ),
          )
          .toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanView(
    List<ProjectTaskItem> todoTasks,
    List<ProjectTaskItem> doingTasks,
    List<ProjectTaskItem> reviewTasks,
    List<ProjectTaskItem> doneTasks,
  ) {
    if (_tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                child: const Icon(Icons.assignment_outlined, color: Color(0xFF6366F1), size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bảng hiện chưa có nhiệm vụ nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhấn "+ Thêm nhiệm vụ" để bắt đầu hoặc khôi phục dữ liệu mẫu.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddTaskDialog('todo'),
                    icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    label: const Text('Thêm nhiệm vụ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _resetSampleTasks,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF6366F1)),
                    label: const Text('Khôi phục dữ liệu mẫu', style: TextStyle(color: Color(0xFF6366F1))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEDE9FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKanbanColumn(
              title: 'Cần làm',
              dotColor: const Color(0xFF64748B),
              tasks: todoTasks,
              statusKey: 'todo',
            ),
            const SizedBox(width: 18),
            _buildKanbanColumn(
              title: 'Đang làm',
              dotColor: const Color(0xFF3B82F6),
              tasks: doingTasks,
              statusKey: 'doing',
            ),
            const SizedBox(width: 18),
            _buildKanbanColumn(
              title: 'Review / Kiểm thử',
              dotColor: const Color(0xFFF59E0B),
              tasks: reviewTasks,
              statusKey: 'review',
            ),
            const SizedBox(width: 18),
            _buildKanbanColumn(
              title: 'Đã hoàn thành',
              dotColor: const Color(0xFF10B981),
              tasks: doneTasks,
              statusKey: 'done',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn({
    required String title,
    required Color dotColor,
    required List<ProjectTaskItem> tasks,
    required String statusKey,
  }) {
    return Container(
      width: 275,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column Header
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showAddTaskDialog(statusKey),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.add_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cards List
          if (tasks.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: const Text(
                'Chưa có nhiệm vụ',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            )
          else
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildTaskCard(tasks[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(ProjectTaskItem item) {
    final tagBg = _getTagBg(item.label);
    final tagFg = _getTagFg(item.label);

    return InkWell(
      onTap: () => _showEditTaskDialog(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Title and 3-dots Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      height: 1.35,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  splashRadius: 14,
                  icon: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditTaskDialog(item);
                    } else if (val == 'delete') {
                      _deleteTask(item.id);
                    } else {
                      _moveTaskStatus(item, val);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      enabled: false,
                      child: Text('Chuyển trạng thái:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    ),
                    PopupMenuItem(
                      value: 'todo',
                      enabled: item.status != 'todo',
                      child: const Text('→ Cần làm', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'doing',
                      enabled: item.status != 'doing',
                      child: const Text('→ Đang làm', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'review',
                      enabled: item.status != 'review',
                      child: const Text('→ Review / Kiểm thử', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'done',
                      enabled: item.status != 'done',
                      child: const Text('→ Đã hoàn thành', style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                          SizedBox(width: 8),
                          Text('Xóa nhiệm vụ', style: TextStyle(fontSize: 12.5, color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tagFg,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Footer (Date & Assignee)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      item.dueDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: item.avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.assignee,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.avatarFg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<ProjectTaskItem> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text(
          'Không có nhiệm vụ nào khớp với bộ lọc',
          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(28),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final tagBg = _getTagBg(task.label);
        final tagFg = _getTagFg(task.label);

        String statusLabel = 'Cần làm';
        Color statusColor = const Color(0xFF64748B);
        if (task.status == 'doing') {
          statusLabel = 'Đang làm';
          statusColor = const Color(0xFF3B82F6);
        } else if (task.status == 'review') {
          statusLabel = 'Review';
          statusColor = const Color(0xFFF59E0B);
        } else if (task.status == 'done') {
          statusLabel = 'Hoàn thành';
          statusColor = const Color(0xFF10B981);
        }

        return InkWell(
          onTap: () => _showEditTaskDialog(task),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(task.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tagFg)),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(task.dueDate, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: task.avatarBg, shape: BoxShape.circle),
                  child: Center(
                    child: Text(task.assignee, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: task.avatarFg)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                  splashRadius: 16,
                  onPressed: () => _deleteTask(task.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryView() {
    final activities = [
      {'user': 'Hoàng Nam', 'action': 'đã thêm nhiệm vụ', 'target': 'Tích hợp giỏ hàng & Checkout One-step', 'time': '10 phút trước', 'avatar': 'HN'},
      {'user': 'Linh Chi', 'action': 'đã chuyển sang Review', 'target': 'Test luồng đặt hàng và voucher giảm giá', 'time': '45 phút trước', 'avatar': 'LC'},
      {'user': 'Trọng Đức', 'action': 'đã hoàn thành', 'target': 'Luồng xác thực và lưu token offline IndexedDB', 'time': '2 giờ trước', 'avatar': 'TD'},
      {'user': 'Phương Anh', 'action': 'đã hoàn thành', 'target': 'Đăng ký tài khoản người dùng', 'time': 'Hôm qua', 'avatar': 'PA'},
      {'user': 'Nam Vũ', 'action': 'đã cập nhật API', 'target': 'Xây dựng API sản phẩm', 'time': '2 ngày trước', 'avatar': 'NV'},
      {'user': 'Hoàng Nam', 'action': 'đã tạo sprint', 'target': 'Sprint 04 – Bảng Dự Án Web Bán Hàng (Phòng IT)', 'time': '08/10/2026', 'avatar': 'HN'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(28),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final act = activities[index];
        final avatar = act['avatar']!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getAssigneeBg(avatar),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getAssigneeFg(avatar)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    children: [
                      TextSpan(text: '${act['user']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${act['action']} ', style: const TextStyle(color: Color(0xFF64748B))),
                      TextSpan(text: '${act['target']}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                act['time']!,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        );
      },
    );
  }
}

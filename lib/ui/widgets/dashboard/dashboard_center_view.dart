import 'package:flutter/material.dart';
import 'package:peertask/models/user/user.dart';
import 'package:peertask/models/board/board.dart';
import 'package:peertask/models/workspace/workspace.dart';
import 'package:peertask/l10n/app_localizations.dart';

class DashboardTaskData {
  final String id;
  final String? boardId;
  final String title;
  final String projectName;
  final String deadline;
  final String status; // 'todo', 'doing', 'done'

  const DashboardTaskData({
    required this.id,
    this.boardId,
    required this.title,
    required this.projectName,
    required this.deadline,
    required this.status,
  });
}

class DashboardBoardCounts {
  final int todo;
  final int doing;
  final int done;
  final int overdue;

  const DashboardBoardCounts({
    this.todo = 0,
    this.doing = 0,
    this.done = 0,
    this.overdue = 0,
  });

  int get total => todo + doing + done;
}

class DashboardCenterView extends StatelessWidget {
  final User? user;
  final Workspace? workspace;
  final List<Board> boards;
  final List<DashboardTaskData>? tasks;
  final Map<String, DashboardBoardCounts>? boardSummaries;
  final VoidCallback onCreateBoard;
  final VoidCallback onViewAllBoards;
  final VoidCallback? onViewAllTasks;
  final ValueChanged<String>? onOpenBoard;
  final ValueChanged<DashboardTaskData>? onOpenTask;

  const DashboardCenterView({
    super.key,
    this.user,
    this.workspace,
    this.boards = const [],
    this.tasks,
    this.boardSummaries,
    required this.onCreateBoard,
    required this.onViewAllBoards,
    this.onViewAllTasks,
    this.onOpenBoard,
    this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Only real data — no fake mock data
    final displayTasks = tasks ?? const <DashboardTaskData>[];
    final displayDoingCount = displayTasks.where((t) => t.status == 'doing').length;
    final displayTodoCount = displayTasks.where((t) => t.status == 'todo').length;
    final displayDoneCount = displayTasks.where((t) => t.status == 'done').length;
    final displayBoardsCount = boards.length;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: ListView(
        padding: MediaQuery.sizeOf(context).width < 600
            ? const EdgeInsets.fromLTRB(16, 16, 16, 32)
            : const EdgeInsets.fromLTRB(28, 20, 28, 48),
        children: [
          // 1. Workspace Hero Banner with Robot mascot & embedded Task Notification
          _buildWorkspaceHeroBanner(
            context,
            l10n,
            displayTasks: displayTasks,
            doingCount: displayDoingCount,
            todoCount: displayTodoCount,
            doneCount: displayDoneCount,
            boardsCount: displayBoardsCount,
          ),
          const SizedBox(height: 24),

          // 2. Two-Column Layout: "Việc của bạn" (Left) and "Bảng của tôi" (Right)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildYourWorkSection(context, l10n, displayTasks),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: _buildMyBoardsSection(context, l10n, boardSummaries),
                    ),
                  ],
                );
              }

              // Stacked layout for narrower viewports
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildYourWorkSection(context, l10n, displayTasks),
                  const SizedBox(height: 24),
                  _buildMyBoardsSection(context, l10n, boardSummaries),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 1. Workspace Hero Banner:
  /// Robot illustration + Title + Desc + Action button on left,
  /// and Task Notification Box replacing the marketing cards on right.
  Widget _buildWorkspaceHeroBanner(
    BuildContext context,
    AppLocalizations l10n, {
    required List<DashboardTaskData> displayTasks,
    required int doingCount,
    required int todoCount,
    required int doneCount,
    required int boardsCount,
  }) {
    final workspaceName = workspace?.name?.isNotEmpty == true ? workspace!.name : l10n.untitled;
    final workspaceDesc = (workspace?.name?.isNotEmpty == true)
        ? 'Không gian làm việc cho các dự án và bảng công việc của $workspaceName.'
        : 'Quản lý và theo dõi các bảng và công việc của bạn.';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;

          final mainBannerContent = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Robot Mascot Illustration
              const _RobotIllustration(),
              const SizedBox(width: 20),

              // Title, Subtitle and Action Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      workspaceName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workspaceDesc,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        if (boards.isNotEmpty) {
                          onOpenBoard?.call(boards.first.id);
                        } else {
                          onCreateBoard();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.getStartedNow,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final notificationCard = _buildTaskNotificationBannerCard(
            context: context,
            l10n: l10n,
            doingCount: doingCount,
            todoCount: todoCount,
            doneCount: doneCount,
            boardsCount: boardsCount,
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 5, child: mainBannerContent),
                const SizedBox(width: 22),
                Expanded(flex: 5, child: notificationCard),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mainBannerContent,
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              notificationCard,
            ],
          );
        },
      ),
    );
  }

  /// Task notification component inside the banner, displaying accurate counts matching existing tasks
  Widget _buildTaskNotificationBannerCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required int doingCount,
    required int todoCount,
    required int doneCount,
    required int boardsCount,
  }) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.todayStatsPrefix,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF581C87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Standout sentence with badges
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.28),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$doingCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.tasksInProgressText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ' ${l10n.localeName == 'vi' ? 'và' : 'and'} ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF581C87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.28),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$boardsCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.boardsText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Three Status Pills: Cần làm, Đang làm, Hoàn thành
          Row(
            children: [
              Expanded(
                child: _buildBannerStatPill(
                  label: l10n.todo,
                  count: todoCount,
                  color: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                  icon: Icons.assignment_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBannerStatPill(
                  label: l10n.inProgress,
                  count: doingCount,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                  icon: Icons.timelapse_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBannerStatPill(
                  label: l10n.done,
                  count: doneCount,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatPill({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 2A. Left Column: "Việc của bạn"
  Widget _buildYourWorkSection(
    BuildContext context,
    AppLocalizations l10n,
    List<DashboardTaskData> displayTasks,
  ) {

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + "Việc của bạn" + "Xem tất cả"
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_box_outlined,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.yourWork,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onViewAllTasks,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    l10n.viewAll,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // List of Task Cards or Empty State
          if (displayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: Color(0xFF94A3B8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.allCaughtUp,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.nothingAssigned,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (int i = 0; i < displayTasks.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildTaskCard(displayTasks[i], l10n),
            ],
          ],

          const SizedBox(height: 16),

          // Quick tip box at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.dashboardTaskTip,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DashboardTaskData task, AppLocalizations l10n) {
    // Stripe & Badge color
    final Color stripeColor;
    final Color badgeBg;
    final Color badgeText;
    final String statusLabel;

    switch (task.status) {
      case 'doing':
        stripeColor = const Color(0xFFF59E0B);
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        statusLabel = l10n.inProgress;
        break;
      case 'done':
        stripeColor = const Color(0xFF10B981);
        badgeBg = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF059669);
        statusLabel = l10n.done;
        break;
      case 'todo':
      default:
        stripeColor = const Color(0xFF3B82F6);
        badgeBg = const Color(0xFFDBEAFE);
        badgeText = const Color(0xFF2563EB);
        statusLabel = l10n.todo;
        break;
    }

    return InkWell(
      onTap: () => onOpenTask?.call(task),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  color: stripeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: badgeText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.projectName,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              task.deadline,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3B. Right Column: "Bảng của tôi"
  Widget _buildMyBoardsSection(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, DashboardBoardCounts>? boardSummaries,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + "Bảng của tôi" + Badge [real count] + "Xem tất cả"
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.myBoards,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${boards.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onViewAllBoards,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    l10n.viewAll,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (boards.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dashboard_outlined,
                        color: Color(0xFF94A3B8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noBoardsYet,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.createFirstBoard,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            for (int i = 0; i < boards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final summary = boardSummaries?[boards[i].id];
                  final total = summary?.total ?? 0;
                  final done = summary?.done ?? 0;
                  final progress = total == 0 ? 0.0 : done / total;
                  return _buildBoardCard(
                    context: context,
                    id: boards[i].id,
                    title: boards[i].name,
                    description: boards[i].description?.trim().isNotEmpty == true
                        ? boards[i].description!
                        : l10n.noDescription,
                    iconColor: i % 2 == 0 ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                    progress: progress,
                    progressColor: i % 2 == 0 ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                    todoCount: summary?.todo ?? 0,
                    doingCount: summary?.doing ?? 0,
                    doneCount: summary?.done ?? 0,
                    l10n: l10n,
                  );
                },
              ),
            ],
          ],

          const SizedBox(height: 12),

          // Card: + Tạo bảng mới
          InkWell(
            onTap: onCreateBoard,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFDDD6FE),
                  style: BorderStyle.solid,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 26,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.createNewBoard,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.createBoardCardDesc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCard({
    required BuildContext context,
    required String id,
    required String title,
    required String description,
    required Color iconColor,
    required double progress,
    required Color progressColor,
    required int todoCount,
    required int doingCount,
    required int doneCount,
    required AppLocalizations l10n,
  }) {
    return InkWell(
      onTap: () => onOpenBoard?.call(id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Icon + Title + Three Dots
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.view_column_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Member / View Kanban
            Row(
              children: [
                const Icon(
                  Icons.view_kanban_outlined,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Kanban',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress stats & bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${todoCount + doingCount + doneCount} ${l10n.tasks.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 5,
              ),
            ),

            const SizedBox(height: 12),

            // Status Pills
            Wrap(
              spacing: 0,
              runSpacing: 6,
              children: [
                _buildStatusPill(
                  label: '${l10n.todo} $todoCount',
                  dotColor: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFF5F3FF),
                  textColor: const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  label: '${l10n.inProgress} $doingCount',
                  dotColor: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFF5F3FF),
                  textColor: const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(
                  label: '${l10n.done} $doneCount',
                  dotColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                  textColor: const Color(0xFF059669),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatarCircle(int index, String initial, Color bgColor) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color dotColor,
    required Color bgColor,
    required Color textColor,
  }) {
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
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A crisp, futuristic cute robot mascot widget drawn with Flutter vector components
class _RobotIllustration extends StatelessWidget {
  const _RobotIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glow
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            ),
          ),
          // Cute sparkles
          const Positioned(
            top: 6,
            right: 8,
            child: Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
          ),
          const Positioned(
            top: 28,
            right: 0,
            child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFF818CF8)),
          ),
          const Positioned(
            bottom: 12,
            left: 2,
            child: Icon(Icons.star_rounded, size: 11, color: Color(0xFFFBBF24)),
          ),
          // Robot Head and Body
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Little cute Antenna
              Container(
                width: 3,
                height: 6,
                color: const Color(0xFF818CF8),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 2),
              // Head
              Container(
                width: 52,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFE0E7FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  // Visor screen
                  child: Container(
                    width: 38,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cyan Glowing Eye Left
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cyan Glowing Eye Right
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Body
              Container(
                width: 38,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                  border: Border.all(color: const Color(0xFFC7D2FE), width: 1.2),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

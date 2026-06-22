import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/firestore/firestore_models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/widgets/app_ui.dart';
import '../dashboard/staff_case_review_page.dart';
import '../dashboard/widgets/app_drawer.dart';
import '../discipline/discipline_page.dart';
import '../lecturer/session_detail_page.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    // Mark as read
    await ref
        .read(notificationServiceProvider)
        .markAsRead(notification.notificationId);

    if (!context.mounted) return;

    if (notification.type == 'warning_alert') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const StaffCaseReviewPage()),
      );
    } else if (notification.type == 'warning_acknowledged') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const DisciplineIssuesPage()),
      );
    } else if (notification.type == 'attendance_reminder' &&
        notification.relatedId != null) {
      final parts = notification.relatedId!.split('|');
      if (parts.isNotEmpty) {
        final sessionId = parts[0];
        final sessions = ref.read(timetableSessionsProvider).value ?? [];
        final sessionMatch = sessions.where(
          (s) => s.timetableSessionId == sessionId,
        );

        if (sessionMatch.isNotEmpty) {
          final session = sessionMatch.first;
          final subjects = ref.read(subjectsProvider).value ?? [];
          final rooms = ref.read(roomsProvider).value ?? [];
          final timeSlots = ref.read(timeSlotsProvider).value ?? [];

          final subject = subjects.firstWhere(
            (s) => s.subjectId == session.subjectId,
            orElse: () => SubjectModel(
              subjectId: session.subjectId,
              code: session.subjectId,
              name: 'Unknown Subject',
              moduleType: '',
              status: 'active',
            ),
          );

          final room = rooms.firstWhere(
            (r) => r.roomId == session.roomId,
            orElse: () => RoomModel(
              roomId: session.roomId,
              name: session.roomId,
              location: '',
              status: 'active',
            ),
          );

          final startSlot = timeSlots.firstWhere(
            (t) => t.timeSlotId == session.startSlotId,
            orElse: () => TimeSlotModel(
              timeSlotId: session.startSlotId,
              slotNo: 0,
              startTime: '??:??',
              endTime: '??:??',
              durationMinutes: 0,
              status: 'active',
            ),
          );

          final endSlot = timeSlots.firstWhere(
            (t) => t.timeSlotId == session.endSlotId,
            orElse: () => TimeSlotModel(
              timeSlotId: session.endSlotId,
              slotNo: 0,
              startTime: '??:??',
              endTime: '??:??',
              durationMinutes: 0,
              status: 'active',
            ),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SessionDetailPage(
                session: session,
                subject: subject,
                room: room,
                startTime: startSlot.startTime,
                endTime: endSlot.endTime,
              ),
            ),
          );
          return;
        }
      }

      // Fallback if session details cannot be resolved
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load session details.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notificationsAsync = ref.watch(notificationsProvider(user.uid));
    final canPop = Navigator.of(context).canPop();

    return AppShell(
      title: 'Notifications',
      drawer: canPop ? null : const AppDrawer(currentPage: 'notifications'),
      actions: [
        notificationsAsync.maybeWhen(
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            final hasUnread = list.any((n) => !n.isRead);
            return Row(
              children: [
                if (hasUnread)
                  IconButton(
                    icon: const Icon(Icons.done_all, color: Color(0xFF0B3A8D)),
                    onPressed: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .markAllAsRead(user.uid);
                    },
                    tooltip: 'Mark all as read',
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    // Confirm delete
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Notifications?'),
                        content: const Text(
                          'This will delete all your notifications permanently.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(notificationServiceProvider)
                          .clearAllNotifications(user.uid);
                    }
                  },
                  tooltip: 'Clear all',
                ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      body: notificationsAsync.when(
        loading: () => const AppLoadingState(label: 'Loading notifications'),
        error: (error, _) =>
            Center(child: Text('Failed to load notifications: $error')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'All caught up',
                message: 'You have no new notifications right now.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationCard(
                notification: notif,
                timeLabel: _formatTimeAgo(notif.createdAt),
                onTap: () => _handleNotificationTap(context, ref, notif),
                onDelete: () async {
                  await ref
                      .read(notificationServiceProvider)
                      .deleteNotification(notif.notificationId);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.timeLabel,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getIcon() {
    return switch (notification.type) {
      'warning_alert' => Icons.warning_amber_rounded,
      'warning_acknowledged' => Icons.check_circle_outline_rounded,
      'attendance_reminder' => Icons.calendar_today_rounded,
      _ => Icons.notifications_active_rounded,
    };
  }

  Color _getIconBgColor() {
    return switch (notification.type) {
      'warning_alert' => const Color(0xFFFEF2F2),
      'warning_acknowledged' => const Color(0xFFF0FDF4),
      'attendance_reminder' => const Color(0xFFFFF7ED),
      _ => const Color(0xFFF0F9FF),
    };
  }

  Color _getIconColor() {
    return switch (notification.type) {
      'warning_alert' => Colors.redAccent,
      'warning_acknowledged' => Colors.green,
      'attendance_reminder' => Colors.orange,
      _ => const Color(0xFF0284C7),
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.primarySoft.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.18),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconBgColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(), color: _getIconColor(), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w700
                                : FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              splashRadius: 16,
              tooltip: 'Delete notification',
            ),
          ],
        ),
      ),
    );
  }
}

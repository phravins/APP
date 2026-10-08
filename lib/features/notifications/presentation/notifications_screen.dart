import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/glass.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final org = ref.watch(organisationProvider);
    return DueDeskScaffold(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: () => runAction(
            context,
            () => ref
                .read(workspaceProvider.notifier)
                .act((r, a) => r.markRead(a, org.id)),
            success: 'All notifications marked as read',
          ),
          child: const Text('Read all'),
        ),
      ],
      child: WorkspaceBody(
        child: PageBody(
          onRefresh: () => ref.read(workspaceProvider.notifier).refresh(),
          children: [
            if (notifications.isEmpty)
              const EmptyState(
                title: 'Nothing new for now.',
                message: 'Reminders and updates will appear here.',
                icon: Icons.notifications_none,
              ),
            for (final n in notifications)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: () async {
                    final ok = await runAction(
                      context,
                      () => ref
                          .read(workspaceProvider.notifier)
                          .act((r, a) => r.markRead(a, org.id, id: n.id)),
                    );
                    if (context.mounted && ok) {
                      context.push('/due/${n.dueItemId}');
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        n.type == 'overdue'
                            ? Icons.warning_amber_rounded
                            : Icons.notifications_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.message,
                              style: TextStyle(
                                fontWeight: n.read
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'd MMM · h:mm a',
                              ).format(n.timestamp.toLocal()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
